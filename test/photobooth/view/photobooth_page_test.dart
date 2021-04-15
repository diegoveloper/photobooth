// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:io_photobooth/assets/assets.dart';
import 'package:io_photobooth/decoration/decoration.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:photobooth_ui/photobooth_ui.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockCameraPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements CameraPlatform {}

class FakeCameraOptions extends Fake implements CameraOptions {}

class MockImage extends Mock implements ui.Image {}

class MockPhotoboothBloc extends MockBloc<PhotoboothEvent, PhotoboothState>
    implements PhotoboothBloc {}

class FakePhotoboothEvent extends Fake implements PhotoboothEvent {}

class FakePhotoboothState extends Fake implements PhotoboothState {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Assets.load();

  setUpAll(() {
    registerFallbackValue<CameraOptions>(FakeCameraOptions());
    registerFallbackValue<PhotoboothEvent>(FakePhotoboothEvent());
    registerFallbackValue<PhotoboothState>(FakePhotoboothState());
  });

  const cameraId = 1;
  late CameraPlatform cameraPlatform;

  setUp(() {
    cameraPlatform = MockCameraPlatform();
    CameraPlatform.instance = cameraPlatform;
    when(() => cameraPlatform.init()).thenAnswer((_) async => {});
    when(
      () => cameraPlatform.create(any()),
    ).thenAnswer((_) async => cameraId);
    when(() => cameraPlatform.play(any())).thenAnswer((_) async => {});
    when(() => cameraPlatform.stop(any())).thenAnswer((_) async => {});
    when(() => cameraPlatform.dispose(any())).thenAnswer((_) async => {});
  });

  group('PhotoboothPage', () {
    test('is routable', () {
      expect(PhotoboothPage.route(), isA<MaterialPageRoute>());
    });

    testWidgets('displays a PhotoboothView', (tester) async {
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(SizedBox());
      await tester.pumpApp(PhotoboothPage());
      await tester.pumpAndSettle();
      expect(find.byType(PhotoboothView), findsOneWidget);
    });
  });

  group('PhotoboothView', () {
    late PhotoboothBloc photoboothBloc;

    setUp(() {
      photoboothBloc = MockPhotoboothBloc();
      when(() => photoboothBloc.state).thenReturn(PhotoboothState());
    });

    testWidgets('renders Camera', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      expect(find.byType(Camera), findsOneWidget);
    });

    testWidgets('renders placholder when initializing', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      expect(find.byType(PhotoboothPlaceholder), findsOneWidget);
    });

    testWidgets('renders error when unavailable', (tester) async {
      when(
        () => cameraPlatform.create(any()),
      ).thenThrow(const CameraUnknownException());
      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoboothError), findsOneWidget);
    });

    testWidgets('renders error when not allowed', (tester) async {
      when(
        () => cameraPlatform.create(any()),
      ).thenThrow(const CameraNotAllowedException());
      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoboothError), findsOneWidget);
    });

    testWidgets('renders preview when available', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PhotoboothPreview), findsOneWidget);
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('renders dash, sparky, and android buttons', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CharacterIconButton), findsNWidgets(3));
    });

    testWidgets('renders only android when only android is selected',
        (tester) async {
      when(() => photoboothBloc.state).thenReturn(
        PhotoboothState(
          isAndroidSelected: true,
          isDashSelected: false,
          isSparkySelected: false,
        ),
      );
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('photoboothPreview_android_draggableResizableAsset'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders only dash when only dash is selected', (tester) async {
      when(() => photoboothBloc.state).thenReturn(
        PhotoboothState(
          isAndroidSelected: false,
          isDashSelected: true,
          isSparkySelected: false,
        ),
      );
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('photoboothPreview_dash_draggableResizableAsset')),
        findsOneWidget,
      );
    });

    testWidgets('renders only sparky when only sparky is selected',
        (tester) async {
      when(() => photoboothBloc.state).thenReturn(
        PhotoboothState(
          isAndroidSelected: false,
          isDashSelected: false,
          isSparkySelected: true,
        ),
      );
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('photoboothPreview_sparky_draggableResizableAsset'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders dash, sparky, and android when all are selected',
        (tester) async {
      when(() => photoboothBloc.state).thenReturn(
        PhotoboothState(
          isAndroidSelected: true,
          isDashSelected: true,
          isSparkySelected: true,
        ),
      );
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DraggableResizableAsset), findsNWidgets(3));
    });

    testWidgets('displays a DesktopCharactersIconLayout', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DesktopCharactersIconLayout), findsOneWidget);
    });

    testWidgets('displays a MobileCharactersIconLayout', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(
        PhotoboothBreakpoints.mobile,
        1000,
      );
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MobileCharactersIconLayout), findsOneWidget);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('tapping on dash button adds DashToggled', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(
        const Key('photoboothView_dash_characterIconButton'),
      ));
      expect(tester.takeException(), isNull);
      verify(() => photoboothBloc.add(PhotoboothDashToggled())).called(1);
    });

    testWidgets('tapping on sparky button adds SparkyToggled', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(
        const Key('photoboothView_sparky_characterIconButton'),
      ));
      expect(tester.takeException(), isNull);
      verify(() => photoboothBloc.add(PhotoboothSparkyToggled())).called(1);
    });

    testWidgets('tapping on android button adds AndroidToggled',
        (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);

      await tester.pumpApp(
        BlocProvider.value(value: photoboothBloc, child: PhotoboothView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(
        const Key('photoboothView_android_characterIconButton'),
      ));
      expect(tester.takeException(), isNull);
      verify(() => photoboothBloc.add(PhotoboothAndroidToggled())).called(1);
    });

    testWidgets('navigates to DecorationPage photo is taken', (tester) async {
      const key = Key('__target__');
      const preview = SizedBox(key: key);
      final image = CameraImage(
        data: Uint8List.fromList(transparentImage),
        width: 4,
        height: 4,
      );
      when(() => cameraPlatform.buildView(cameraId)).thenReturn(preview);
      when(
        () => cameraPlatform.takePicture(cameraId),
      ).thenAnswer((_) async => image);

      await tester.runAsync(() async {
        await tester.pumpApp(
          BlocProvider.value(
            value: photoboothBloc,
            child: PhotoboothView(enablePoseDetection: true),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump();

        await tester.tap(find.byType(CameraButton));
        await tester.pumpAndSettle();
        expect(find.byType(DecorationPage), findsOneWidget);

        final decorationPage =
            tester.widget<DecorationPage>(find.byType(DecorationPage));
        expect(decorationPage.image, isNotNull);
        expect(find.byType(DecorationPage), findsOneWidget);
        await tester
            .tap(find.byKey(const Key('decorationPage_back_iconButton')));
        await tester.pumpAndSettle();
        expect(find.byType(PhotoboothView), findsOneWidget);
      });
    });
  });
}
