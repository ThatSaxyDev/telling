# Telling store artwork — 14 October 2026

28 finished PNG images, grouped by upload destination. Upload the PNGs inside the matching folder. The folder names include their exact pixel dimensions.

| Folder | Upload destination | Dimensions | Images |
| --- | --- | --- | --- |
| 01-iPhone-medium-1179x2556 | App Store: iPhone 6.1 / 6.3-inch medium display screenshots | 1179 × 2556 | 5 |
| 02-iPad-13-2064x2752 | App Store: iPad 13-inch screenshots | 2064 × 2752 | 5 |
| 03-Duo-outer-1398x2034 | App Store: Duo screenshots, outer format | 1398 × 2034 | 5 |
| 04-Duo-inner-2007x2853 | App Store: Duo screenshots, inner format | 2007 × 2853 | 5 |
| 05-Header-3840x1646 | App Store: Header asset | 3840 × 1646 | 1 |
| 06-Search-Results-3840x2560 | App Store: Search Results asset | 3840 × 2560 | 1 |
| 07-Play-phone-1080x1920 | Google Play: Phone screenshots | 1080 × 1920 | 5 |
| 08-Play-feature-1024x500 | Google Play: Feature graphic | 1024 × 500 | 1 |

Use the ascending numbered order within each screenshot set: overview, error details, session timeline, analytics, and version controls. Duo folders are two format options for that slot; select the format corresponding to the intended display rather than mixing duplicate versions of the same five screenshots.

These are still screenshots and artwork. App previews are videos; these PNGs belong in screenshot/image fields. Header, Search Results, and Google Play Feature Graphic have separate fields.

## Content and capture

The first headline is “See what's happening in your app.” The design retains Telling’s black-and-white identity, original fonts, and existing severity colors. Funnels is omitted because there is no populated view to demonstrate.

The iPhone content comes from the supplied Telling screenshots. iPad images were captured from the app’s real Flutter tablet layout on a 13-inch iPad simulator, rather than stretching phone content. Google Play screenshots use genuine Android emulator captures. Their local sample data is isolated in `tool/store_artboard_capture.dart`; the capture entrypoint does not initialize the live analytics or notification SDKs. Duo compositions preserve the source phone UI’s proportions.

Three app layout fixes support the tablet/Android capture: more vertical space for tablet overview cards, sufficient tablet bottom navigation height, and a guard against painting a zero-size grid. The tablet layout regression tests cover portrait and landscape. Include these changes in the release build so the store artwork matches the shipped layout. Build releases using the normal `lib/main.dart` entrypoint.

## Verification

`validation.json` records the decoded pixel dimensions, RGB mode, file size, source, and SHA-256 of every final PNG. All 28 files passed exact dimensions and opaque RGB checks. The renderer also checks for image loading, heading/frame overlap, canvas overflow, and proportional screen scaling. The compositions were visually inspected.

`index.html` is the image gallery for review. The files are prepared for upload; no store listing or review submission has been performed.

References: [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), [Apple asset best practices](https://developer.apple.com/app-store/asset-best-practices/), [Google Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151). Header, Search Results, and Duo dimensions also match the upload fields supplied in this conversation.
