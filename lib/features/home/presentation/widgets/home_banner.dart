import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() {
    return _HomeBannerState();
  }
}

class _HomeBannerState extends State<HomeBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final slides = [
      _HeroSlide(
        kicker: l10n.heroLaptopKicker,
        title: l10n.heroLaptopTitle,
        subtitle: l10n.heroLaptopSubtitle,
        icon: Icons.laptop_mac_rounded,
        colors: const [Color(0xFF3166B3), Color(0xFF5E5CE6)],
      ),
      _HeroSlide(
        kicker: l10n.heroMobileKicker,
        title: l10n.heroMobileTitle,
        subtitle: l10n.heroMobileSubtitle,
        icon: Icons.phone_iphone_rounded,
        colors: const [Color(0xFFE85D24), Color(0xFFD51F4B)],
      ),
      _HeroSlide(
        kicker: l10n.heroGamingKicker,
        title: l10n.heroGamingTitle,
        subtitle: l10n.heroGamingSubtitle,
        icon: Icons.sports_esports_rounded,
        colors: const [Color(0xFF007A63), Color(0xFF15947F)],
      ),
    ];

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          itemBuilder: (context, index, realIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BannerCard(slide: slides[index]),
            );
          },
          options: CarouselOptions(
            height: 160,
            viewportFraction: 0.94,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < slides.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentIndex ? 20 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.slide});

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.colors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    slide.kicker,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  slide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(slide.icon, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}
