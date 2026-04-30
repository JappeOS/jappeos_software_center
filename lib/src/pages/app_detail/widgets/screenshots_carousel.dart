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

class ScreenshotsCarousel extends StatefulWidget {
  final List<String> screenshots;

  const ScreenshotsCarousel({super.key, required this.screenshots});

  @override
  State<ScreenshotsCarousel> createState() => _ScreenshotsCarouselState();
}

class _ScreenshotsCarouselState extends State<ScreenshotsCarousel> {
  final CarouselController controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    if (widget.screenshots.isEmpty) {
      return SizedBox(
        width: 800,
        height: 220,
        child: OutlinedContainer(
          child: Center(
            child: Text('No screenshots available for this source.').muted(),
          ),
        ),
      );
    }

    return SizedBox(
      width: 800,
      child: Row(
        children: [
          OutlineButton(
            shape: ButtonShape.circle,
            onPressed: () {
              controller.animatePrevious(const Duration(milliseconds: 125));
            },
            child: const Icon(Icons.arrow_back),
          ),
          const Gap(24),
          Expanded(
            child: SizedBox(
              height: 400,
              child: Carousel(
                transition: const CarouselTransition.sliding(gap: 24),
                controller: controller,
                sizeConstraint: const CarouselFixedConstraint(400),
                autoplaySpeed: Duration.zero,
                itemCount: widget.screenshots.length,
                itemBuilder: (context, index) {
                  final screenshot = widget.screenshots[index];
                  return OutlinedContainer(
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      screenshot,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text('Failed to load screenshot').muted(),
                        );
                      },
                    ),
                  );
                },
                duration: const Duration(seconds: 1),
              ),
            ),
          ),
          const Gap(24),
          OutlineButton(
            shape: ButtonShape.circle,
            onPressed: () {
              controller.animateNext(const Duration(milliseconds: 125));
            },
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
