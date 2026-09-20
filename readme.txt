| Color            | Hex       | Main purpose                             |
| ---------------- | --------- | ---------------------------------------- |
| **Primary Cyan** | `#00C6D4` | Main brand, buttons, active states       |
| **Accent Pink**  | `#FF2D7A` | Favorites, important actions, highlights |
| **Light Cyan**   | `#E6F9FB` | Soft backgrounds, info sections          |
| **Soft Gray**    | `#F2F4F7` | Secondary backgrounds, cards/input areas |
| **Dark Text**    | `#1A1A1A` | Headings and primary text                |
| White            | `#FFFFFF` | Main background/cards                    |
| Secondary Gray   | `#6B7280` | Descriptions, metadata                   |
| Border Gray      | `#E5E7EB` | Borders/dividers                         |





lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   │
│   ├── router/
│   │   └── app_router.dart
│   │
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_dimensions.dart
│
├── core/
│   │
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   │
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_exception.dart
│   │   └── api_interceptor.dart
│   │
│   ├── storage/
│   │   └── secure_storage_service.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── extensions.dart
│   │   └── helpers.dart
│   │
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_loader.dart
│       └── app_error_view.dart
│
├── data/
│   │
│   ├── models/
│   │   ├── auth/
│   │   │   ├── login_request.dart
│   │   │   ├── login_response.dart
│   │   │   ├── register_request.dart
│   │   │   ├── register_response.dart
│   │   │   └── user_model.dart
│   │   │
│   │   ├── property/
│   │   │   ├── property_model.dart
│   │   │   └── property_image_model.dart
│   │   │
│   │   └── common/
│   │       └── api_response.dart
│   │
│   ├── services/
│   │   ├── auth_api_service.dart
│   │   ├── property_api_service.dart
│   │   └── user_api_service.dart
│   │
│   └── repositories/
│       ├── auth_repository.dart
│       ├── property_repository.dart
│       └── user_repository.dart
│
└── features/
    │
    ├── auth/
    │   │
    │   └── presentation/
    │       ├── screens/
    │       │   ├── splash_screen.dart
    │       │   ├── get_started_screen.dart
    │       │   ├── login_screen.dart
    │       │   ├── register_screen.dart
    │       │   ├── forgot_password_screen.dart
    │       │   └── reset_password_screen.dart
    │       │
    │       ├── viewmodels/
    │       │   ├── login_view_model.dart
    │       │   ├── register_view_model.dart
    │       │   └── forgot_password_view_model.dart
    │       │
    │       └── widgets/
    │           ├── auth_text_field.dart
    │           └── social_login_button.dart
    │
    ├── home/
    │   │
    │   └── presentation/
    │       ├── screens/
    │       │   └── home_screen.dart
    │       ├── viewmodels/
    │       │   └── home_view_model.dart
    │       └── widgets/
    │
    ├── properties/
    │   │
    │   └── presentation/
    │       ├── screens/
    │       │   ├── properties_screen.dart
    │       │   ├── property_details_screen.dart
    │       │   └── property_search_screen.dart
    │       ├── viewmodels/
    │       │   ├── properties_view_model.dart
    │       │   └── property_details_view_model.dart
    │       └── widgets/
    │           ├── property_card.dart
    │           └── property_image.dart
    │
    ├── favorites/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    ├── messages/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    ├── notifications/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    ├── profile/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    ├── buyer/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    ├── seller/
    │   └── presentation/
    │       ├── screens/
    │       ├── viewmodels/
    │       └── widgets/
    │
    └── agent/
        └── presentation/
            ├── screens/
            ├── viewmodels/
            └── widgets/










            seller/
│
├── data/
│   └── services/
│       └── seller_service.dart
│
├── models/
│   ├── property.dart
│   ├── property_feature.dart
│   ├── property_financials.dart
│   ├── property_legal_details.dart
│   └── property_media.dart
│
└── presentation/
    │
    ├── screens/
    │   │
    │   ├── seller_activation_screen.dart
    │   ├── SellerMyPropertiesScreen.dart
    │   │
    │   └── create_property/
    │       │
    │       ├── create_property_screen.dart
    │       ├── property_type_screen.dart
    │       ├── property_basic_screen.dart
    │       ├── property_location_screen.dart
    │       ├── property_details_screen.dart
    │       ├── property_features_screen.dart
    │       ├── property_financials_screen.dart
    │       ├── property_legal_screen.dart
    │       ├── property_media_screen.dart
    │       └── property_review_screen.dart
    │
    └── widgets/
        ├── listing_step_indicator.dart
        ├── listing_bottom_buttons.dart
        ├── property_form_section.dart
        ├── property_image_grid.dart
        └── property_summary_card.dart