import json
import logging
import os
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required

dermatologists_bp = Blueprint(
    "dermatologists", __name__, url_prefix="/api/dermatologists"
)

_PLACES_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"
_PLACES_FIELD_MASK = (
    "places.id,places.displayName,places.formattedAddress,places.rating,"
    "places.userRatingCount,places.currentOpeningHours,places.regularOpeningHours,"
    "places.nationalPhoneNumber,places.websiteUri,places.location"
)
_LOGGER = logging.getLogger(__name__)


def _search_google_places(latitude, longitude, radius, api_key):
    search_request = Request(
        _PLACES_SEARCH_URL,
        data=json.dumps(
            {
                "textQuery": "dermatologist",
                "maxResultCount": 20,
                "rankPreference": "RELEVANCE",
                "locationBias": {
                    "circle": {
                        "center": {
                            "latitude": latitude,
                            "longitude": longitude,
                        },
                        "radius": float(radius),
                    }
                },
            }
        ).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": _PLACES_FIELD_MASK,
        },
        method="POST",
    )
    try:
        with urlopen(search_request, timeout=20) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        if exc.code in (401, 403):
            raise RuntimeError(
                "Google Places denied the request. Check the Places API (New), billing, and key restrictions."
            ) from exc
        raise RuntimeError(
            "Google Places could not complete the search. Please try again."
        ) from exc
    except (URLError, TimeoutError, OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(
            "Google Places could not be reached. Please try again."
        ) from exc

    if not isinstance(payload, dict):
        raise RuntimeError(
            "Google Places returned an invalid response. Please try again."
        )

    if "error" in payload:
        error = payload.get("error") or {}
        _LOGGER.warning(
            "Google Places search failed: %s", error.get("message", "unknown error")
        )
        raise RuntimeError(
            "Google Places could not complete the search. Check the Places API configuration and try again."
        )
    return payload


@dermatologists_bp.get("/nearby")
@jwt_required()
def nearby_dermatologists():
    api_key = os.getenv("GOOGLE_MAPS_API_KEY", "").strip()
    if not api_key or api_key == "YOUR_GOOGLE_API_KEY_HERE":
        return (
            jsonify(
                message="Nearby dermatologist search is not configured on the server."
            ),
            503,
        )

    try:
        latitude = float(request.args.get("latitude", ""))
        longitude = float(request.args.get("longitude", ""))
        radius = int(request.args.get("radius", "10000"))
    except (TypeError, ValueError):
        return (
            jsonify(message="latitude, longitude and radius must be valid numbers."),
            400,
        )

    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        return (
            jsonify(message="The supplied location is outside valid coordinates."),
            400,
        )
    if not 1 <= radius <= 50000:
        return jsonify(message="radius must be between 1 and 50000 meters."), 400

    try:
        payload = _search_google_places(latitude, longitude, radius, api_key)
    except RuntimeError as exc:
        return jsonify(message=str(exc)), 502

    results = []
    for place in payload.get("places", [])[:20]:
        if not isinstance(place, dict) or not place.get("id"):
            continue
        opening_hours = place.get("currentOpeningHours") or {}
        regular_hours = place.get("regularOpeningHours") or {}
        display_name = place.get("displayName") or {}
        location = place.get("location") or {}
        results.append(
            {
                "place_id": place["id"],
                "name": display_name.get("text") or "Dermatologist",
                "address": place.get("formattedAddress") or "Address not available",
                "rating": place.get("rating"),
                "total_ratings": place.get("userRatingCount", 0),
                "is_open_now": opening_hours.get("openNow"),
                "phone_number": place.get("nationalPhoneNumber"),
                "website": place.get("websiteUri"),
                "opening_hours": regular_hours.get("weekdayDescriptions"),
                "latitude": location.get("latitude"),
                "longitude": location.get("longitude"),
            }
        )

    return jsonify(results=results), 200
