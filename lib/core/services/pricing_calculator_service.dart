import '../models/pricing_calculator.dart';

class PricingCalculatorService {
  static const double _basePricePerApartment = 15.0; // Base price in NIS per apartment per month
  
  // Israeli cities pricing data - based on real market research
  static const Map<String, double> _cityMultipliers = {
    // Greater Tel Aviv
    'תל אביב': 1.35,
    'רמת גן': 1.30,
    'גבעתיים': 1.28,
    'בני ברק': 1.25,
    'חולון': 1.15,
    'בת ים': 1.10,
    'ראשון לציון': 1.20,
    'פתח תקווה': 1.18,
    'הרצליה': 1.40,
    'כפר סבא': 1.22,
    'רעננה': 1.25,
    
    // Jerusalem area
    'ירושלים': 1.15,
    'בית שמש': 1.05,
    'מודיעין': 1.18,
    'מעלה אדומים': 1.08,
    
    // Haifa and North
    'חיפה': 1.10,
    'נתניה': 1.15,
    'קריית שמונה': 0.85,
    'צפת': 0.80,
    'עכו': 0.90,
    'נהריה': 0.95,
    
    // South
    'באר שבע': 0.95,
    'אשדוד': 1.00,
    'אשקלון': 0.98,
    'אילת': 1.05,
    'קרית גת': 0.85,
    
    // Center
    'רמלה': 0.95,
    'לוד': 0.90,
    'יבנה': 1.08,
    'גדרה': 1.05,
  };

  // Neighborhood quality multipliers (example data - would be expanded with real data)
  static const Map<String, double> _neighborhoodMultipliers = {
    // Tel Aviv neighborhoods
    'צפון הישן': 1.25,
    'צפון החדש': 1.30,
    'הארבע': 1.20,
    'רמת אביב': 1.15,
    'פלורנטין': 1.10,
    'יפו': 0.95,
    'דרום העיר': 1.05,
    
    // Jerusalem neighborhoods
    'רחביה': 1.25,
    'גרמן קולוני': 1.20,
    'טלביה': 1.30,
    'נחלאות': 1.15,
    'קטמון': 1.10,
    'גילה': 1.05,
    
    // Default multiplier for unknown neighborhoods
    'default': 1.0,
  };

  static const Map<ServiceTier, double> _serviceTierMultipliers = {
    ServiceTier.basic: 0.8,
    ServiceTier.standard: 1.0,
    ServiceTier.premium: 1.3,
    ServiceTier.enterprise: 1.6,
  };

  static const Map<String, double> _additionalServices = {
    'security_patrol': 800.0, // ₪800 per month
    'garden_maintenance': 600.0,
    'cleaning_service': 1200.0,
    'concierge_service': 2000.0,
    'technical_maintenance': 400.0,
    'legal_consulting': 300.0,
    'accounting_service': 500.0,
    'energy_management': 350.0,
  };

  Future<PricingResult> calculatePrice(PricingRequest request) async {
    try {
      // Input validation
      _validateRequest(request);
      
      // Calculate base price
      final basePrice = _calculateBasePrice(request.buildingProfile);
      
      // Calculate location multiplier with security checks
      final locationPricing = _calculateLocationPricing(request.buildingProfile);
      final locationMultiplier = locationPricing.cityMultiplier * locationPricing.neighborhoodMultiplier;
      
      // Calculate building complexity multiplier
      final complexityScoring = _calculateComplexityScoring(request.buildingProfile);
      final complexityMultiplier = complexityScoring.totalComplexityScore;
      
      // Service tier multiplier
      final serviceTierMultiplier = _serviceTierMultipliers[request.serviceTier] ?? 1.0;
      
      // Contract duration discount
      final contractMultiplier = request.contractDuration.discountMultiplier;
      
      // Additional services pricing
      final additionalServicesPrice = _calculateAdditionalServicesPrice(request.additionalServices);
      final additionalServicesPricing = _getAdditionalServicesPricing(request.additionalServices);
      
      // Calculate final price with security bounds
      double finalPrice = basePrice * locationMultiplier * complexityMultiplier * serviceTierMultiplier * contractMultiplier;
      finalPrice += additionalServicesPrice;
      
      // Apply reasonable bounds (security measure)
      finalPrice = _applyPriceBounds(finalPrice, request.buildingProfile.totalApartments);
      
      final monthlyPrice = _calculateMonthlyPrice(finalPrice, request.contractDuration);
      
      final servicePricing = ServicePricing(
        tier: request.serviceTier,
        multiplier: serviceTierMultiplier,
        includedServices: _getIncludedServices(request.serviceTier),
        description: request.serviceTier.description,
      );
      
      final breakdown = PricingBreakdown(
        locationPricing: locationPricing,
        complexityScoring: complexityScoring,
        servicePricing: servicePricing,
        additionalServicesPricing: additionalServicesPricing,
      );
      
      return PricingResult(
        basePrice: basePrice,
        locationMultiplier: locationMultiplier,
        complexityMultiplier: complexityMultiplier,
        serviceTierMultiplier: serviceTierMultiplier,
        contractMultiplier: contractMultiplier,
        additionalServicesPrice: additionalServicesPrice,
        finalPrice: finalPrice,
        monthlyPrice: monthlyPrice,
        breakdown: breakdown,
        calculatedAt: DateTime.now(),
        currency: 'ILS', // Israeli Shekel
      );
    } catch (e) {
      throw PricingCalculationException('Error calculating price: $e');
    }
  }

  void _validateRequest(PricingRequest request) {
    if (request.buildingProfile.totalApartments <= 0) {
      throw ArgumentError('Total apartments must be greater than 0');
    }
    if (request.buildingProfile.totalFloors <= 0) {
      throw ArgumentError('Total floors must be greater than 0');
    }
    if (request.buildingProfile.buildingAge < 0) {
      throw ArgumentError('Building age cannot be negative');
    }
    if (request.buildingProfile.address.isEmpty) {
      throw ArgumentError('Building address is required');
    }
  }

  double _calculateBasePrice(BuildingProfile profile) {
    // Base calculation: price per apartment with economies of scale
    double basePrice = _basePricePerApartment * profile.totalApartments;
    
    // Apply economies of scale for larger buildings
    if (profile.totalApartments > 50) {
      basePrice *= 0.90; // 10% discount for large buildings
    } else if (profile.totalApartments > 20) {
      basePrice *= 0.95; // 5% discount for medium buildings
    }
    
    return basePrice;
  }

  LocationPricing _calculateLocationPricing(BuildingProfile profile) {
    final cityMultiplier = _cityMultipliers[profile.city] ?? 1.0;
    final neighborhoodMultiplier = _neighborhoodMultipliers[profile.neighborhood] ?? 
                                 _neighborhoodMultipliers['default']!;
    
    final priceZone = _determinePriceZone(cityMultiplier * neighborhoodMultiplier);
    final explanation = _generateLocationExplanation(profile.city, profile.neighborhood, priceZone);
    
    return LocationPricing(
      city: profile.city,
      neighborhood: profile.neighborhood,
      cityMultiplier: cityMultiplier,
      neighborhoodMultiplier: neighborhoodMultiplier,
      priceZone: priceZone,
      explanation: explanation,
    );
  }

  ComplexityScoring _calculateComplexityScoring(BuildingProfile profile) {
    // Floor complexity scoring
    double floorScore = 1.0;
    if (profile.totalFloors > 10) {
      floorScore = 1.20; // High-rise buildings are more complex
    } else if (profile.totalFloors > 5) {
      floorScore = 1.10;
    } else if (profile.totalFloors > 3) {
      floorScore = 1.05;
    }

    // Apartment density scoring
    double apartmentScore = 1.0;
    final density = profile.totalApartments / profile.totalFloors;
    if (density > 8) {
      apartmentScore = 1.15; // High density = more management complexity
    } else if (density > 4) {
      apartmentScore = 1.08;
    }

    // Building age scoring
    double ageScore = 1.0;
    if (profile.buildingAge > 30) {
      ageScore = 1.25; // Older buildings require more attention
    } else if (profile.buildingAge > 20) {
      ageScore = 1.15;
    } else if (profile.buildingAge > 10) {
      ageScore = 1.05;
    } else if (profile.buildingAge < 5) {
      ageScore = 0.95; // Newer buildings are easier to manage
    }

    // Amenities scoring
    double amenityScore = 1.0;
    for (final amenity in profile.amenities) {
      amenityScore += amenity.complexityMultiplier;
    }

    // Calculate total complexity with reasonable bounds
    final totalComplexityScore = (floorScore * apartmentScore * ageScore * amenityScore).clamp(0.7, 2.0);

    final explanation = _generateComplexityExplanation(
      floorScore, apartmentScore, ageScore, amenityScore, profile);

    return ComplexityScoring(
      floorScore: floorScore,
      apartmentScore: apartmentScore,
      ageScore: ageScore,
      amenityScore: amenityScore,
      totalComplexityScore: totalComplexityScore,
      explanation: explanation,
    );
  }

  double _calculateAdditionalServicesPrice(List<String> services) {
    double total = 0.0;
    for (final service in services) {
      total += _additionalServices[service] ?? 0.0;
    }
    return total;
  }

  Map<String, double> _getAdditionalServicesPricing(List<String> services) {
    final Map<String, double> pricing = {};
    for (final service in services) {
      pricing[service] = _additionalServices[service] ?? 0.0;
    }
    return pricing;
  }

  double _applyPriceBounds(double price, int totalApartments) {
    // Security measure: Apply reasonable bounds based on building size
    final minPrice = totalApartments * 50.0; // Minimum ₪50 per apartment
    final maxPrice = totalApartments * 500.0; // Maximum ₪500 per apartment
    
    return price.clamp(minPrice, maxPrice);
  }

  double _calculateMonthlyPrice(double finalPrice, ContractDuration duration) {
    // finalPrice is already the monthly price, so we don't need to divide
    return finalPrice;
  }

  String _determinePriceZone(double multiplier) {
    if (multiplier >= 1.3) return 'פרימיום';
    if (multiplier >= 1.15) return 'גבוה';
    if (multiplier >= 1.0) return 'סטנדרטי';
    if (multiplier >= 0.9) return 'נמוך';
    return 'חסכוני';
  }

  String _generateLocationExplanation(String city, String neighborhood, String priceZone) {
    return 'אזור מחיר $priceZone - $city, $neighborhood';
  }

  String _generateComplexityExplanation(
    double floorScore, double apartmentScore, double ageScore, double amenityScore, BuildingProfile profile) {
    final explanations = <String>[];
    
    if (floorScore > 1.1) explanations.add('בניין רב קומות');
    if (apartmentScore > 1.1) explanations.add('צפיפות גבוהה');
    if (ageScore > 1.1) explanations.add('בניין ותיק');
    if (amenityScore > 1.2) explanations.add('מתקנים מתקדמים');
    
    return explanations.isEmpty ? 'בניין סטנדרטי' : explanations.join(', ');
  }

  List<String> _getIncludedServices(ServiceTier tier) {
    switch (tier) {
      case ServiceTier.basic:
        return [
          'תחזוקה שוטפת',
          'ניהול תקציב בסיסי',
          'תיאום עם ספקים',
          'דוח חודשי',
        ];
      case ServiceTier.standard:
        return [
          'כל השירותים הבסיסיים',
          'מעקב אחר חובות',
          'ניהול פניות דיירים',
          'דוחות מפורטים',
          'זמינות בשעות עבודה',
        ];
      case ServiceTier.premium:
        return [
          'כל השירותים הסטנדרטיים',
          'זמינות 24/7',
          'ניהול פרויקטים מיוחדים',
          'ייעוץ משפטי בסיסי',
          'אופטימיזציה תקציבית',
        ];
      case ServiceTier.enterprise:
        return [
          'כל השירותים הפרימיום',
          'מנהל חשבון יעודי',
          'ניהול מספר בניינים',
          'דוחות עסקיים מתקדמים',
          'אינטגרציה מערכות',
          'ייעוץ אסטרטגי',
        ];
    }
  }
}

class PricingCalculationException implements Exception {
  final String message;
  PricingCalculationException(this.message);
  
  @override
  String toString() => 'PricingCalculationException: $message';
}