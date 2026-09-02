<!-- ============================================================
     head.php – Reusable Head Section Include
     ============================================================ -->

<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />

<title><?php echo isset($page_title) ? $page_title : 'Business Name · Default Title'; ?></title>

<meta name="description" content="<?php echo isset($page_description) ? $page_description : 'A clean, up‑to‑date website with a modern navigation bar.'; ?>" />

<!-- Open Graph / Social Media -->
<meta property="og:title" content="<?php echo isset($og_title) ? $og_title : (isset($page_title) ? $page_title : 'Business Name'); ?>" />
<meta property="og:description" content="<?php echo isset($og_description) ? $og_description : (isset($page_description) ? $page_description : 'A clean, up‑to‑date website with a modern navigation bar.'); ?>" />
<meta property="og:type" content="website" />
<meta property="og:url" content="<?php echo isset($og_url) ? $og_url : 'https://example.com'; ?>" />
<meta property="og:image" content="<?php echo isset($og_image) ? $og_image : 'https://example.com/og-image.jpg'; ?>" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="<?php echo isset($twitter_title) ? $twitter_title : (isset($page_title) ? $page_title : 'Business Name'); ?>" />
<meta name="twitter:description" content="<?php echo isset($twitter_description) ? $twitter_description : (isset($page_description) ? $page_description : 'A clean, up‑to‑date website with a modern navigation bar.'); ?>" />
<meta name="twitter:image" content="<?php echo isset($twitter_image) ? $twitter_image : (isset($og_image) ? $og_image : 'https://example.com/og-image.jpg'); ?>" />

<!-- Theme Color -->
<meta name="theme-color" content="#1a1a1a" />

<!-- Favicon -->
<link rel="icon" type="image/png" sizes="32x32" href="assets/graphics/avatar.png" />
<link rel="apple-touch-icon" sizes="180x180" href="assets/graphics/avatar.png" />

<!-- Canonical URL -->
<link rel="canonical" href="<?php echo isset($canonical_url) ? $canonical_url : 'https://example.com'; ?>" />

<!-- Robots -->
<meta name="robots" content="<?php echo isset($robots) ? $robots : 'index, follow'; ?>" />

<!-- Viewport / Responsive (already set above) -->

<!-- Business Schema.org JSON-LD -->
<script type="application/ld+json">
{
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    "name": "<?php echo isset($business_name) ? $business_name : 'Your Business Name'; ?>",
    "description": "<?php echo isset($business_description) ? $business_description : 'A clean, up‑to‑date website with a modern navigation bar.'; ?>",
    "url": "<?php echo isset($business_url) ? $business_url : 'https://example.com'; ?>",
    "logo": "<?php echo isset($business_logo) ? $business_logo : 'https://example.com/logo.png'; ?>",
    "address": {
        "@type": "PostalAddress",
        "streetAddress": "<?php echo isset($business_street) ? $business_street : '123 Main Street'; ?>",
        "addressLocality": "<?php echo isset($business_city) ? $business_city : 'Springfield'; ?>",
        "addressRegion": "<?php echo isset($business_region) ? $business_region : 'IL'; ?>",
        "postalCode": "<?php echo isset($business_postal) ? $business_postal : '62701'; ?>",
        "addressCountry": "<?php echo isset($business_country) ? $business_country : 'US'; ?>"
    },
    "contactPoint": {
        "@type": "ContactPoint",
        "telephone": "<?php echo isset($business_phone) ? $business_phone : '+1-800-555-1234'; ?>",
        "contactType": "customer service",
        "availableLanguage": ["English"]
    },
    "openingHours": "<?php echo isset($business_hours) ? $business_hours : 'Mo-Fr 09:00-17:00'; ?>",
    "sameAs": [
        <?php echo isset($social_links) ? implode(', ', array_map(function($link) { return '"' . $link . '"'; }, $social_links)) : '"https://facebook.com/yourpage", "https://twitter.com/yourpage"'; ?>
    ]
}
</script>

<!-- CSS Stylesheets -->
<link rel="stylesheet" href="assets/styles/navbar.css" />
<link rel="stylesheet" href="assets/styles/branding.css" />
<link rel="stylesheet" href="assets/styles/typography.css" />
<link rel="stylesheet" href="assets/styles/footer.css" />
<?php if (isset($extra_css)): ?>
    <?php foreach ($extra_css as $css_file): ?>
        <link rel="stylesheet" href="<?php echo $css_file; ?>" />
    <?php endforeach; ?>
<?php endif; ?>

<!-- Google Fonts (optional - add if needed) -->
<?php if (isset($google_fonts)): ?>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?<?php echo $google_fonts; ?>&display=swap" rel="stylesheet" />
<?php endif; ?>

<!-- Additional head content (for page-specific meta, scripts, etc.) -->
<?php if (isset($extra_head)): ?>
    <?php echo $extra_head; ?>
<?php endif; ?>
