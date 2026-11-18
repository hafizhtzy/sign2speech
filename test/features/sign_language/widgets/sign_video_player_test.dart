import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/widgets/sign_video_player.dart';

void main() {
  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('id', 'ID');
  });

  Widget buildTestableWidget(Widget child) {
    return GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('SignVideoPlayer Widget Tests', () {
    testWidgets(
      'renders player controls, play/pause button, and timeline indicators',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        bool playPauseChanged = false;
        bool isPlayingState = false;

        await tester.pumpWidget(
          buildTestableWidget(
            SignVideoPlayer(
              playlist: const [
                SignVideoEntry(
                  id: 'kopi_v1',
                  label: 'Kopi',
                  aliases: ['kopi'],
                  category: 'minuman',
                  assetPath: 'assets/video_offline/kopi.mp4',
                  remoteUrl: '',
                  source: SignVideoSource.asset,
                ),
                SignVideoEntry(
                  id: 'susu_v1',
                  label: 'Susu',
                  aliases: ['susu'],
                  category: 'minuman',
                  assetPath: 'assets/video_offline/susu.mp4',
                  remoteUrl: '',
                  source: SignVideoSource.asset,
                ),
              ],
              activeWordIndex: 0,
              videoSource: 'assets/video_offline/kopi.mp4',
              onPlayPauseChanged: (val) {
                playPauseChanged = true;
                isPlayingState = val;
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify active word label is displayed
        expect(find.text('Kopi'), findsWidgets);

        // Verify playlist choice chips
        expect(find.text('Susu'), findsOneWidget);

        // Verify offline badge is displayed
        expect(find.text(AppStrings.signVideoOfflineBadge.tr), findsOneWidget);

        // Verify Play/Pause icon button exists in playback controls row
        final playPauseFinder = find.byTooltip(AppStrings.signVideoPlay.tr);
        expect(playPauseFinder, findsOneWidget);

        // Verify Replay and Loop buttons exist
        expect(find.byTooltip(AppStrings.signVideoReplay.tr), findsOneWidget);
        expect(find.byTooltip(AppStrings.signVideoLoop.tr), findsOneWidget);

        // Verify playback speed selector chips exist
        expect(find.text('0.75x'), findsOneWidget);
        expect(find.text('1.0x'), findsOneWidget);
        expect(find.text('1.25x'), findsOneWidget);

        // Verify timeline indicator text exists
        expect(find.text('00:00 / 00:00'), findsOneWidget);

        // Callback initial state check
        expect(playPauseChanged, isFalse);
        expect(isPlayingState, isFalse);
      },
    );

    testWidgets(
      'renders online badge and download action when video source is remote',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        bool downloadTriggered = false;

        await tester.pumpWidget(
          buildTestableWidget(
            SignVideoPlayer(
              playlist: const [
                SignVideoEntry(
                  id: 'pisang_goreng_v1',
                  label: 'Pisang Goreng',
                  aliases: ['pisang'],
                  category: 'makanan',
                  assetPath: '',
                  remoteUrl:
                      'https://sign2speech-cloud.supabase.co/storage/v1/object/public/sign-videos/videos/bisindo/pisang_goreng_v1.mp4',
                  source: SignVideoSource.remote,
                ),
              ],
              activeWordIndex: 0,
              videoSource:
                  'https://sign2speech-cloud.supabase.co/storage/v1/object/public/sign-videos/videos/bisindo/pisang_goreng_v1.mp4',
              onDownload: () {
                downloadTriggered = true;
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify online badge is displayed
        expect(find.text(AppStrings.signVideoOnlineBadge.tr), findsOneWidget);

        // Verify download button exists and can be tapped
        final downloadBtnFinder = find.widgetWithText(
          InkWell,
          AppStrings.signVideoDownloadAction.tr,
        );
        expect(downloadBtnFinder, findsOneWidget);

        await tester.tap(downloadBtnFinder);
        expect(downloadTriggered, isTrue);
      },
    );

    testWidgets('renders cached badge when video source is local file', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const SignVideoPlayer(
            playlist: [
              SignVideoEntry(
                id: 'teh_v1',
                label: 'Teh',
                aliases: ['teh'],
                category: 'minuman',
                assetPath: '',
                remoteUrl: '',
                cachedFilePath: '/data/user/0/com.example/files/teh_v1.mp4',
                source: SignVideoSource.localCached,
              ),
            ],
            activeWordIndex: 0,
            videoSource: '/data/user/0/com.example/files/teh_v1.mp4',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify cached badge is displayed
      expect(find.text(AppStrings.signVideoCachedBadge.tr), findsOneWidget);
    });

    testWidgets('renders smooth animated downloading view when isDownloading is true', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const SignVideoPlayer(
            playlist: [
              SignVideoEntry(
                id: 'kopi_v1',
                label: 'Kopi',
                aliases: ['kopi'],
                category: 'minuman',
                assetPath: '',
                remoteUrl: 'https://example.com/kopi.mp4',
                source: SignVideoSource.remote,
              ),
            ],
            activeWordIndex: 0,
            videoSource: 'https://example.com/kopi.mp4',
            isDownloading: true,
            downloadProgress: 0.65,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Verify downloading title and percentage are displayed
      expect(find.text(AppStrings.signVideoDownloadingTitle.tr), findsOneWidget);
      expect(find.textContaining('65%'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download_rounded), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'accepts onVideoCompleted callback for sequential multi-word playlists',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            SignVideoPlayer(
              playlist: const [
                SignVideoEntry(
                  id: 'pesan_v1',
                  label: 'Pesan',
                  aliases: ['pesan'],
                  category: 'transaksi',
                  assetPath: 'assets/video_offline/pesan.mp4',
                  remoteUrl: '',
                  source: SignVideoSource.asset,
                ),
                SignVideoEntry(
                  id: 'kopi_v1',
                  label: 'Kopi',
                  aliases: ['kopi'],
                  category: 'minuman',
                  assetPath: 'assets/video_offline/kopi.mp4',
                  remoteUrl: '',
                  source: SignVideoSource.asset,
                ),
              ],
              activeWordIndex: 0,
              videoSource: 'assets/video_offline/pesan.mp4',
              isLooping: true,
              onVideoCompleted: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Pesan'), findsWidgets);
        expect(find.text('Kopi'), findsOneWidget);
      },
    );
  });
}
