<!-- ============================================================
navbar.php – Reusable Navigation Include (using <details>)
============================================================ -->

<header class="navbar" role="banner">

<!-- Logo / Business Name -->
<a href="/" class="navbar-brand">
<span class="logo-icon"><img class='logo' src='assets/graphics/avatar.png' /></span>
<span>de marca digital</span>
</a>

<!-- Desktop Navigation -->
<ul class="nav-links">
<li><a href="/#home">Home</a></li>
<li><a href="/#services">Services</a></li>
<li><a href="/#reviews">Reviews</a></li>
<li><a href="/#faq">FAQ</a></li>
<li><a href="/#blog">Blog</a></li>
<li><a href="/#blog">Contact Us</a></li>
</ul>

<!-- Mobile Hamburger using <details> -->
<details class="hamburger-wrapper">
<summary class="hamburger" aria-label="Toggle navigation menu">
<span></span>
<span></span>
<span></span>
</summary>

<!-- Mobile Menu (appears when details is open) -->
<div class="mobile-menu">
<nav>
<a href="/#home">Home</a>
<a href="/#about">About</a>
<a href="/#services">Services</a>
<a href="/#contact">Contact</a>
</nav>
</div>
</details>

</header>
