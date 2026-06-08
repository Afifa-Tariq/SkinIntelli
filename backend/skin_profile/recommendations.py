from collections import OrderedDict

INGREDIENT_RULES = {
    "Oily": ["Niacinamide", "Salicylic Acid"],
    "Dry": ["Hyaluronic Acid", "Ceramides"],
    "Combination": ["Niacinamide", "Hyaluronic Acid"],
    "Sensitive": ["Centella Asiatica", "Aloe Vera"],
    "Normal": ["Vitamin C", "SPF"],
}

CONCERN_RULES = {
    "Acne": ["Benzoyl Peroxide", "Tea Tree Oil"],
    "Dark Spots": ["Vitamin C", "Alpha Arbutin"],
    "Wrinkles": ["Retinol", "Peptides"],
    "Dryness": ["Ceramides", "Squalane"],
    "Redness": ["Centella Asiatica", "Azelaic Acid"],
}

ENVIRONMENT_RULES = {
    "Polluted Area": ["Antioxidants", "Vitamin E"],
    "Humid Area": ["Lightweight Gel Moisturizer"],
    "Dry Climate": ["Rich Moisturizer", "Facial Oil"],
}

INGREDIENT_BENEFITS = {
    "Niacinamide": "Controls oil production and minimizes pores",
    "Salicylic Acid": "Exfoliates pores and reduces blemishes",
    "Hyaluronic Acid": "Hydrates skin by retaining moisture",
    "Ceramides": "Restores the skin barrier and locks in hydration",
    "Centella Asiatica": "Soothes irritation and reduces redness",
    "Aloe Vera": "Calms sensitive or inflamed skin",
    "Vitamin C": "Brightens skin and fades dark spots",
    "SPF": "Protects skin from UV damage",
    "Benzoyl Peroxide": "Clears acne-causing bacteria",
    "Tea Tree Oil": "Helps reduce inflammation and breakouts",
    "Alpha Arbutin": "Evens skin tone and fades hyperpigmentation",
    "Retinol": "Boosts collagen production and smooths fine lines",
    "Peptides": "Supports skin firmness and resilience",
    "Squalane": "Softens and nourishes dry skin",
    "Azelaic Acid": "Reduces redness and calms sensitive skin",
    "Antioxidants": "Protects skin from environmental stressors",
    "Vitamin E": "Supports skin repair and barrier health",
    "Lightweight Gel Moisturizer": "Delivers hydration without heaviness",
    "Rich Moisturizer": "Provides deep nourishment in dry climates",
    "Facial Oil": "Seals in moisture and protects against dryness",
}

PRODUCT_RULES = {
    "Niacinamide": ("Balancing Serum", "Morning"),
    "Salicylic Acid": ("Clarifying Treatment", "Night"),
    "Hyaluronic Acid": ("Hydrating Serum", "Morning"),
    "Ceramides": ("Repair Moisturizer", "Night"),
    "Centella Asiatica": ("Soothing Gel", "Morning"),
    "Aloe Vera": ("Calming Gel", "Night"),
    "Vitamin C": ("Brightening Serum", "Morning"),
    "SPF": ("Broad-Spectrum Sunscreen", "Morning"),
    "Benzoyl Peroxide": ("Acne Spot Treatment", "Night"),
    "Tea Tree Oil": ("Clarifying Oil", "Night"),
    "Alpha Arbutin": ("Tone Correction Serum", "Morning"),
    "Retinol": ("Retinol Treatment", "Night"),
    "Peptides": ("Firming Serum", "Night"),
    "Squalane": ("Nourishing Oil", "Night"),
    "Azelaic Acid": ("Redness Relief Serum", "Morning"),
    "Antioxidants": ("Antioxidant Mist", "Morning"),
    "Vitamin E": ("Protective Oil", "Night"),
    "Lightweight Gel Moisturizer": ("Gel Moisturizer", "Morning"),
    "Rich Moisturizer": ("Cream Moisturizer", "Night"),
    "Facial Oil": ("Facial Oil", "Night"),
}

TIP_RULES = {
    "Oily": "Use non-comedogenic products and cleanse with gentle exfoliants.",
    "Dry": "Layer lightweight hydrators with richer creams at night.",
    "Combination": "Target oily zones with lightweight products and drier zones with hydration.",
    "Sensitive": "Patch test new products and choose soothing, fragrance-free formulas.",
    "Normal": "Maintain a balanced routine with daily protection and hydration.",
    "Polluted Area": "Cleanse thoroughly in the evening to remove buildup from pollution.",
    "Humid Area": "Opt for breathable textures and avoid heavy creams.",
    "Dry Climate": "Use occlusive moisturizers and hydrating oils to lock in moisture.",
}


def _get_profile_value(profile, key, default=None):
    if isinstance(profile, dict):
        return profile.get(key, default)
    return getattr(profile, key, default)


def generate_recommendations(skin_profile):
    skin_type = _get_profile_value(skin_profile, "skin_type")
    skin_concerns = _get_profile_value(skin_profile, "skin_concerns") or []
    environment = _get_profile_value(skin_profile, "environment")

    if not isinstance(skin_concerns, list):
        skin_concerns = [skin_concerns]

    ingredients = OrderedDict()

    if skin_type in INGREDIENT_RULES:
        for name in INGREDIENT_RULES[skin_type]:
            ingredients[name] = INGREDIENT_BENEFITS.get(name, "Supports skin health.")

    for concern_name, concern_ingredients in CONCERN_RULES.items():
        if any(concern_name.lower() in str(concern).lower() for concern in skin_concerns):
            for name in concern_ingredients:
                ingredients[name] = INGREDIENT_BENEFITS.get(name, "Supports skin health.")

    if environment in ENVIRONMENT_RULES:
        for name in ENVIRONMENT_RULES[environment]:
            ingredients[name] = INGREDIENT_BENEFITS.get(name, "Supports skin health.")

    products = OrderedDict()
    for ingredient in ingredients:
        product = PRODUCT_RULES.get(ingredient)
        if product:
            products[product[0]] = product[1]

    if skin_type == "Oily" and "SPF" not in products:
        products["Broad-Spectrum Sunscreen"] = "Morning"

    tips = []
    if skin_type in TIP_RULES:
        tips.append(TIP_RULES[skin_type])
    if environment in TIP_RULES:
        tips.append(TIP_RULES[environment])
    if not tips:
        tips.append("Follow a consistent routine and adjust products based on how your skin feels.")

    return {
        "ingredients": [
            {"name": name, "benefit": benefit}
            for name, benefit in ingredients.items()
        ],
        "products": [
            {"name": name, "time_of_day": time_of_day}
            for name, time_of_day in products.items()
        ],
        "tips": tips,
    }
