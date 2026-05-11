import 'package:flutter/material.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/location.png",
      "title": "Discover What's Happening Nearby",
      "desc": "Find real events from verified community groups and clubs — all in one place.",
    },
    {
      "image": "assets/images/Calendar.png",
      "title": "Events Sync Automatically",
      "desc": "No manual setup — we integrate directly with group calendars for real-time updates.",
    },
    {
      "image": "assets/images/reminder.png",
      "title": "Shape the Next\nBig Event",
      "desc": "Vote on new event ideas, favorite your picks, and never miss what matters most.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // ── White base ──────────────────────────────────────────

          // ── Pattern overlay: multiply blends black→transparent ──
          // Black pixels become invisible, red pattern shows on white
          Opacity(
            opacity: 0.8, // ← lower = lighter pattern, raise to darken
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.multiply,
              ),
              child: SizedBox.expand(
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── Foreground UI ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Skip button
                if (currentIndex != pages.length - 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, "/login");
                        },
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Color(0xFFCF3232),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFCF3232),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.097,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: imageSize,
                              height: imageSize,
                              child: Image.asset(
                                pages[index]["image"]!,
                                fit: BoxFit.contain,
                              ),
                            ),

                            SizedBox(height: size.height * 0.01),

                            Text(
                              pages[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width * 0.084,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(offset: Offset(0.5, 0.5))
                                ]                       ,         color: Colors.black, // ← dark text on white bg
                              ),
                            ),

                            SizedBox(height: size.height * 0.015),

                            Text(
                              pages[index]["desc"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: Colors.black54, // ← readable on white
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04,),
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: currentIndex == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? const Color(0xFFCF3232)
                            : const Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                SizedBox(height: size.height * 0.04),

                // Button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.width * 0.05,
                    0,
                    size.width * 0.05,
                    size.height * 0.03,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCF3232),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, size.height * 0.065),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (currentIndex == pages.length - 1) {
                        Navigator.pushReplacementNamed(context, "/login");
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      currentIndex == pages.length - 1 ? "Get Started" : "Next",
                      style: TextStyle(fontSize: size.width * 0.045),
                    ),
                  ),
                ),SizedBox(height: MediaQuery.of(context).size.height * 0.04,)
              ],
            ),
          ),
        ],
      ),
    );
  }
}