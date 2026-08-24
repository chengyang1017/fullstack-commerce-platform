import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() {
    return _HomeBannerState();
  }
}

class _HomeBannerState extends State<HomeBanner> {
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    final banners = [
      _HeroBannerData(
        kicker: l10n.heroLaptopKicker,
        title: l10n.heroLaptopTitle,
        subtitle: l10n.heroLaptopSubtitle,
        icon: Icons.laptop_mac_rounded,
        startColor: colorScheme.primary,
        endColor: const Color(0xFF4338CA),
      ),
      _HeroBannerData(
        kicker: l10n.heroMobileKicker,
        title: l10n.heroMobileTitle,
        subtitle: l10n.heroMobileSubtitle,
        icon: Icons.phone_iphone_rounded,
        startColor: const Color(0xFFEA580C),
        endColor: const Color(0xFFBE123C),
      ),
      _HeroBannerData(
        kicker: l10n.heroGamingKicker,
        title: l10n.heroGamingTitle,
        subtitle: l10n.heroGamingSubtitle,
        icon: Icons.sports_esports_rounded,
        startColor: const Color(0xFF047857),
        endColor: const Color(0xFF0F766E),
      ),
    ];

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: banners.length,
            itemBuilder: (context, index, realIndex) {
              return _HeroBanner(data: banners[index]);
            },
            options: CarouselOptions(
              height: 200,
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 650),
              onPageChanged: (index, reason) {
                setState(() {
                  _bannerIndex = index;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final selected = index == _bannerIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: selected ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.data});

  final _HeroBannerData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.startColor, data.endColor],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -90,
            right: 40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          Positioned(
            right: 22,
            top: 26,
            bottom: 26,
            child: Container(
              width: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(data.icon, size: 68, color: Colors.white),
            ),
          ),

          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 150, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      data.kicker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannerData {
  const _HeroBannerData({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}
