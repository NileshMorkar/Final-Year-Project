class PlaceFromCoordinates {
  PlusCode? plusCode;
  List<Results>? results;
  String? status;

  PlaceFromCoordinates({this.plusCode, this.results, this.status});

  PlaceFromCoordinates.fromJson(Map<String, dynamic> json) {
    plusCode =
        json['plus_code'] != null
            ? new PlusCode.fromJson(json['plus_code'])
            : null;
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results!.add(new Results.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.plusCode != null) {
      data['plus_code'] = this.plusCode!.toJson();
    }
    if (this.results != null) {
      data['results'] = this.results!.map((v) => v.toJson()).toList();
    }
    data['status'] = this.status;
    return data;
  }
}

class PlusCode {
  String? globalCode;

  PlusCode({this.globalCode});

  PlusCode.fromJson(Map<String, dynamic> json) {
    globalCode = json['global_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['global_code'] = this.globalCode;
    return data;
  }
}

class Results {
  List<AddressComponents>? addressComponents;
  String? formattedAddress;
  Geometry? geometry;
  String? placeId;
  PlusCode? plusCode;
  List<String>? types;

  Results({
    this.addressComponents,
    this.formattedAddress,
    this.geometry,
    this.placeId,
    this.plusCode,
    this.types,
  });

  Results.fromJson(Map<String, dynamic> json) {
    if (json['address_components'] != null) {
      addressComponents = <AddressComponents>[];
      json['address_components'].forEach((v) {
        addressComponents!.add(new AddressComponents.fromJson(v));
      });
    }
    formattedAddress = json['formatted_address'];
    geometry =
        json['geometry'] != null
            ? new Geometry.fromJson(json['geometry'])
            : null;
    placeId = json['place_id'];
    plusCode =
        json['plus_code'] != null
            ? new PlusCode.fromJson(json['plus_code'])
            : null;
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.addressComponents != null) {
      data['address_components'] =
          this.addressComponents!.map((v) => v.toJson()).toList();
    }
    data['formatted_address'] = this.formattedAddress;
    if (this.geometry != null) {
      data['geometry'] = this.geometry!.toJson();
    }
    data['place_id'] = this.placeId;
    if (this.plusCode != null) {
      data['plus_code'] = this.plusCode!.toJson();
    }
    data['types'] = this.types;
    return data;
  }
}

class AddressComponents {
  String? longName;
  String? shortName;
  List<String>? types;

  AddressComponents({this.longName, this.shortName, this.types});

  AddressComponents.fromJson(Map<String, dynamic> json) {
    longName = json['long_name'];
    shortName = json['short_name'];
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['long_name'] = this.longName;
    data['short_name'] = this.shortName;
    data['types'] = this.types;
    return data;
  }
}

class Geometry {
  Bounds? bounds;
  Southwest? location;
  String? locationType;
  Bounds? viewport;

  Geometry({this.bounds, this.location, this.locationType, this.viewport});

  Geometry.fromJson(Map<String, dynamic> json) {
    bounds =
        json['bounds'] != null ? new Bounds.fromJson(json['bounds']) : null;
    location =
        json['location'] != null
            ? new Southwest.fromJson(json['location'])
            : null;
    locationType = json['location_type'];
    viewport =
        json['viewport'] != null ? new Bounds.fromJson(json['viewport']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.bounds != null) {
      data['bounds'] = this.bounds!.toJson();
    }
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['location_type'] = this.locationType;
    if (this.viewport != null) {
      data['viewport'] = this.viewport!.toJson();
    }
    return data;
  }
}

class Bounds {
  Northeast? northeast;
  Northeast? southwest;

  Bounds({this.northeast, this.southwest});

  Bounds.fromJson(Map<String, dynamic> json) {
    northeast =
        json['northeast'] != null
            ? new Northeast.fromJson(json['northeast'])
            : null;
    southwest =
        json['southwest'] != null
            ? new Northeast.fromJson(json['southwest'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.northeast != null) {
      data['northeast'] = this.northeast!.toJson();
    }
    if (this.southwest != null) {
      data['southwest'] = this.southwest!.toJson();
    }
    return data;
  }
}

class Northeast {
  double? lat;
  double? lng;

  Northeast({this.lat, this.lng});

  Northeast.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}

class Southwest {
  double? lat;
  double? lng;

  Southwest({this.lat, this.lng});

  Southwest.fromJson(Map<String, dynamic> json) {
    lat = (json['lat'] as num?)?.toDouble();
    lng = (json['lng'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}
