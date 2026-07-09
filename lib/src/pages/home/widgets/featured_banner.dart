//  jappeos_software_center, A GUI app for installing software for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:math';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app.dart';
import '../../../widgets/app_icon.dart';

enum FeaturedColor {
  blue,
  green,
  orange,
  gray,
}

class FeaturedItem {
  final String id;
  final String title;
  final String description;
  final FeaturedColor color;
  final String imageUrl;
  final void Function()? onInstall;
  final void Function()? onLearnMore;

  FeaturedItem({
    required this.id,
    required this.title,
    required this.description,
    this.color = FeaturedColor.blue,
    required this.imageUrl,
    this.onInstall,
    this.onLearnMore,
  });
}

class FeaturedBanner extends StatefulWidget {
  final List<FeaturedItem> items;

  const FeaturedBanner({super.key, required this.items});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _autoscroll;

  // Blue
  final bluePrimary = Colors.blue[600];
  final blueGradient = [
    Color.fromARGB(255, 8, 12, 22),
    Color.fromARGB(255, 9, 20, 38),
    Color.fromARGB(255, 8, 20, 52),
    Color.fromARGB(255, 12, 26, 49),
  ];

  // Green
  final greenPrimary = Colors.green[600];
  final greenGradient = [
    Color.fromARGB(255, 8, 22, 13),
    Color.fromARGB(255, 9, 38, 19),
    Color.fromARGB(255, 8, 52, 23),
    Color.fromARGB(255, 12, 49, 24),
  ];

  // Orange
  final orangePrimary = Colors.orange[600];
  final orangeGradient = [
    Color.fromARGB(255, 22, 15, 8),
    Color.fromARGB(255, 38, 24, 9),
    Color.fromARGB(255, 52, 30, 8),
    Color.fromARGB(255, 49, 30, 12),
  ];

  // Gray
  final grayPrimary = Colors.gray[600];
  final grayGradient = [
    Color.fromARGB(255, 15, 15, 15),
    Color.fromARGB(255, 24, 24, 24),
    Color.fromARGB(255, 30, 30, 30),
    Color.fromARGB(255, 30, 30, 30),
  ];

  @override
  void initState() {
    super.initState();
    final random = Random();
    final firstPage = random.nextInt(widget.items.length);
    _controller = PageController(initialPage: firstPage);
    _currentPage = firstPage;
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page?.round() ?? 0;
      });
    });
    _resetTimer();
  }

  @override
  void dispose() {
    _autoscroll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    var next = _currentPage++;
    if (next > widget.items.length - 1) {
      next = 0;
    }
    _setPage(next);
  }

  void _setPage(int page) {
    _controller.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _resetTimer() {
    _autoscroll?.cancel();
    _autoscroll = Timer.periodic(Duration(seconds: 7), (_) => _nextPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = kThemeDark;
    final current = widget.items[_currentPage];
    List<Color> gradient = [];
    Color primary;
    switch (current.color) {
      case FeaturedColor.blue:
        gradient = blueGradient;
        primary = bluePrimary;
        break;
      case FeaturedColor.green:
        gradient = greenGradient;
        primary = greenPrimary;
        break;
      case FeaturedColor.orange:
        gradient = orangeGradient;
        primary = orangePrimary;
        break;
      case FeaturedColor.gray:
        gradient = grayGradient;
        primary = grayPrimary;
        break;
    }
    return SizedBox(
      height: 200,
      child: Theme(
        data: theme,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: theme.borderRadiusLg,
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 24 * theme.scaling,
                left: 24 * theme.scaling,
                bottom: 24 * theme.scaling,
                right: 24 * theme.scaling,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 250,
                          child: _buildMainContent(item, theme, primary),
                        ),
                        Spacer(flex: 2),
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: item.imageUrl.isNotEmpty
                              ? (item.imageUrl.endsWith(".svg")
                                  ? SvgPicture.asset(item.imageUrl, fit: BoxFit.cover)
                                  : Image.asset(item.imageUrl, fit: BoxFit.cover))
                              : AppIcon(icon: item.id, size: 150),
                        ),
                        Spacer(flex: 2),
                      ],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment(0.0, 0.9),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: DotIndicator(
                    index: _currentPage,
                    length: widget.items.length,
                    onChanged: (value) {
                      _setPage(value);
                      _resetTimer();
                    },
                  ),
                ),
              ).ignoreSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(FeaturedItem item, ThemeData theme, Color primary) => Column(
    spacing: 8 * Theme.of(context).scaling,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Theme(
        data: theme.copyWith(
          colorScheme: () => theme.colorScheme.copyWith(
            primary: () => primary,
            primaryForeground: () => Colors.white,
          ),
        ),
        child: PrimaryBadge(
          child: Text("Featured"),
        ),
      ),
      Gap(2 * theme.scaling),
      Text(
        item.title,
        style: theme.typography.h3.copyWith(color: Colors.white),
      )/*.asSkeleton(enabled: widget.skeleton)*/,
      Expanded(child: Text(item.description, maxLines: 2).muted().ellipsis())/*.asSkeleton(enabled: widget.skeleton)*/,
      //Spacer(),
      Row(
        spacing: 8 * Theme.of(context).scaling,
        children: [
          PrimaryButton(
            onPressed: item.onInstall,
            child: Text("Install")/*.asSkeleton(enabled: widget.skeleton)*/,
          ),
          OutlineButton(
            onPressed: item.onLearnMore,
            child: Text("Learn more")/*.asSkeleton(enabled: widget.skeleton)*/,
          ),
        ],
      ),
    ],
  );
}