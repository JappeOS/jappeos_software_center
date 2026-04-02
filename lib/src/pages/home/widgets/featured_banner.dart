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

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app.dart';

class FeatuedItem {
  final String title;
  final String description;
  final String imageUrl;
  final void Function()? onInstall;
  final void Function()? onLearnMore;

  FeatuedItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.onInstall,
    this.onLearnMore,
  });
}

class FeaturedBanner extends StatefulWidget {
  final FeatuedItem item;

  const FeaturedBanner({super.key, required this.item});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  @override
  Widget build(BuildContext context) {
    final theme = kThemeDark;
    return SizedBox(
      height: 200,
      child: Theme(
        data: theme,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: theme.borderRadiusLg,
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 8, 12, 22),
                Color.fromARGB(255, 9, 20, 38),
                Color.fromARGB(255, 8, 20, 52),
                Color.fromARGB(255, 12, 26, 49),
              ],
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
                child: Row(
                  children: [
                    SizedBox(
                      width: 230,
                      child: _buildMainContent(theme),
                    ),
                    Spacer(flex: 2),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.network(widget.item.imageUrl),
                    ),
                    Spacer(flex: 2),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: DotIndicator(index: 0, length: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) => Column(
    spacing: 8 * Theme.of(context).scaling,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Theme(
        data: theme.copyWith(
          colorScheme: () => theme.colorScheme.copyWith(
            primary: () => Colors.blue[600],
            primaryForeground: () => Colors.white,
          ),
        ),
        child: PrimaryBadge(
          child: Text("Featured"),
        ),
      ),
      Gap(2 * theme.scaling),
      Text(
        widget.item.title,
        style: theme.typography.h3.copyWith(color: Colors.white),
      ),
      Text(widget.item.description).muted(),
      Spacer(),
      Row(
        spacing: 8 * Theme.of(context).scaling,
        children: [
          PrimaryButton(
            onPressed: widget.item.onInstall,
            child: Text("Install"),
          ),
          OutlineButton(
            onPressed: widget.item.onLearnMore,
            child: Text("Learn more"),
          ),
        ],
      ),
    ],
  );
}