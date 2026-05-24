# ToolVault AI App Store Assets

Premium dark industrial launch assets for App Store Connect.

## App Store screenshots

- `iPhone_6_9/`: 6 screenshots at `1320x2868`
- `iPhone_6_5/`: 6 screenshots at `1242x2688`
- `iPad_13/`: 6 screenshots at `2064x2752`
- `iPad_12_9/`: 6 screenshots at `2048x2732`

Upload the `iPhone_6_9` and `iPad_13` sets first. The `iPhone_6_5` and `iPad_12_9` sets are included as accepted fallback sizes.

## Subscription assets

- `SubscriptionReview/toolvault_ai_pro_monthly_review.png`
- `SubscriptionReview/toolvault_ai_pro_yearly_review.png`
- `SubscriptionReview/toolvault_ai_business_monthly_review.png`

Use these in each subscription's review information screenshot field.

Optional promotional images:

- `SubscriptionPromotional/toolvault_ai_pro_monthly_promo.png`
- `SubscriptionPromotional/toolvault_ai_business_monthly_promo.png`

## App icon

- `Marketing/toolvault_ai_icon_1024.png`: 1024x1024 marketing icon preview
- `../ToolVaultAI/Resources/Assets.xcassets/AppIcon.appiconset/`: Xcode app icon set used by the target

Regenerate everything with:

```bash
python scripts/generate_app_store_assets.py
```
