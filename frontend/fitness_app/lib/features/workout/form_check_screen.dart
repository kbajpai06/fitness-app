import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';

class FormCheckScreen extends StatefulWidget {
  final String exerciseName;
  const FormCheckScreen({super.key, required this.exerciseName});

  @override
  State<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends State<FormCheckScreen> {
  CameraController?  _cameraCtrl;
  PoseDetector?      _poseDetector;
  bool               _isProcessing = false;
  bool               _cameraReady  = false;
  Pose?              _currentPose;
  int                _repCount     = 0;
  int                _formScore    = 0;
  List<String>       _feedback     = [];
  String             _phase        = 'Get Ready';
  bool               _wasDown      = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  // ── Camera Init ───────────────────────────────────────────
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _phase = 'Camera permission denied');
      return;
    }

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream));

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // prefer front camera
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraCtrl = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraCtrl!.initialize();
    if (!mounted) return;

    setState(() => _cameraReady = true);

    _cameraCtrl!.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;
      try {
        await _processFrame(image);
      } finally {
        _isProcessing = false;
      }
    });
  }

  // ── Process Frame ─────────────────────────────────────────
  Future<void> _processFrame(CameraImage image) async {
    if (_poseDetector == null || _cameraCtrl == null) return;

    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    final poses = await _poseDetector!.processImage(inputImage);
    if (poses.isEmpty) {
      if (mounted) setState(() => _phase = 'Stand in frame');
      return;
    }

    final pose     = poses.first;
    final exercise = widget.exerciseName.toLowerCase();
    FormResult result;

    if (exercise.contains('squat')) {
      result = _analyseSquat(pose);
    } else if (exercise.contains('push') || exercise.contains('pushup')) {
      result = _analysePushup(pose);
    } else if (exercise.contains('deadlift')) {
      result = _analyseDeadlift(pose);
    } else if (exercise.contains('pull up') || exercise.contains('pullup')) {
      result = _analysePullUp(pose);
    } else {
      result = _analyseGeneral(pose);
    }

    // Rep counting
    if (result.isDown && !_wasDown) {
      _wasDown = true;
    } else if (!result.isDown && _wasDown) {
      _wasDown = false;
      _repCount++;
    }

    if (mounted) {
      setState(() {
        _currentPose = pose;
        _formScore   = result.score;
        _feedback    = result.feedback;
        _phase       = result.phase;
      });
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_cameraCtrl == null) return null;
    final camera   = _cameraCtrl!.description;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

    if (image.format.group != ImageFormatGroup.nv21) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Exercise Analysers ────────────────────────────────────

  FormResult _analyseSquat(Pose pose) {
    final lHip   = pose.landmarks[PoseLandmarkType.leftHip];
    final lKnee  = pose.landmarks[PoseLandmarkType.leftKnee];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (lHip == null || lKnee == null || lAnkle == null) {
      return FormResult.notVisible();
    }

    final kneeAngle   = _angle(lHip, lKnee, lAnkle);
    final isDown      = kneeAngle < 110;
    int   score       = 0;
    final feedback    = <String>[];

    // Depth check
    if (kneeAngle < 90) {
      score += 30;
      feedback.add('✅ Great depth!');
    } else if (kneeAngle < 110) {
      score += 20;
      feedback.add('⚠️ Go a bit deeper');
    } else {
      feedback.add('❌ Need more depth');
    }

    // Knee alignment
    final kneeCave = (lKnee.x - lAnkle.x).abs();
    if (kneeCave < 40) {
      score += 25;
      feedback.add('✅ Knees tracking well');
    } else {
      feedback.add('⚠️ Knees caving in');
    }

    // Back angle
    if (lShoulder != null) {
      final backAngle = _angle(lShoulder, lHip, lKnee);
      if (backAngle > 150) {
        score += 25;
        feedback.add('✅ Back straight');
      } else {
        feedback.add('⚠️ Keep chest up');
      }
    } else {
      score += 20;
    }

    score += 20; // base score

    return FormResult(
      score:    score.clamp(0, 100),
      feedback: feedback,
      phase:    isDown ? '⬇️ Down' : '⬆️ Up',
      isDown:   isDown,
    );
  }

  FormResult _analysePushup(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final lHip      = pose.landmarks[PoseLandmarkType.leftHip];
    final lAnkle    = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return FormResult.notVisible();
    }

    final elbowAngle = _angle(lShoulder, lElbow, lWrist);
    final isDown     = elbowAngle < 100;
    int   score      = 0;
    final feedback   = <String>[];

    // Elbow angle at bottom
    if (elbowAngle < 90) {
      score += 30;
      feedback.add('✅ Full range of motion');
    } else if (elbowAngle < 110) {
      score += 20;
      feedback.add('⚠️ Go a bit lower');
    } else {
      feedback.add('❌ Need more depth');
    }

    // Body straight check
    if (lHip != null && lAnkle != null) {
      final hipDrop = lHip.y - lShoulder.y;
      if (hipDrop.abs() < 30) {
        score += 30;
        feedback.add('✅ Body straight');
      } else {
        feedback.add('⚠️ Keep hips level');
      }
    } else {
      score += 25;
    }

    // Elbow flare
    final flare = (lElbow.x - lShoulder.x).abs();
    if (flare < 60) {
      score += 25;
      feedback.add('✅ Elbows tucked');
    } else {
      feedback.add('⚠️ Tuck elbows in');
    }

    score += 15;

    return FormResult(
      score:    score.clamp(0, 100),
      feedback: feedback,
      phase:    isDown ? '⬇️ Down' : '⬆️ Up',
      isDown:   isDown,
    );
  }

  FormResult _analyseDeadlift(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lHip      = pose.landmarks[PoseLandmarkType.leftHip];
    final lKnee     = pose.landmarks[PoseLandmarkType.leftKnee];
    final lAnkle    = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (lHip == null || lKnee == null || lShoulder == null) {
      return FormResult.notVisible();
    }

    final hipAngle   = _angle(lShoulder, lHip, lKnee);
    final isDown     = hipAngle < 130;
    int   score      = 0;
    final feedback   = <String>[];

    // Back straightness
    if (lAnkle != null) {
      final backAngle = _angle(lShoulder, lHip, lAnkle);
      if (backAngle > 160) {
        score += 35;
        feedback.add('✅ Back neutral');
      } else if (backAngle > 140) {
        score += 20;
        feedback.add('⚠️ Slight rounding');
      } else {
        feedback.add('❌ Back rounding — stop!');
      }
    }

    // Hip hinge
    if (hipAngle < 100) {
      score += 30;
      feedback.add('✅ Good hip hinge');
    } else if (hipAngle < 130) {
      score += 20;
      feedback.add('⚠️ Hinge more at hips');
    }

    score += 35;

    return FormResult(
      score:    score.clamp(0, 100),
      feedback: feedback,
      phase:    isDown ? '⬇️ Lowering' : '⬆️ Lifting',
      isDown:   isDown,
    );
  }

  FormResult _analysePullUp(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final lHip      = pose.landmarks[PoseLandmarkType.leftHip];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return FormResult.notVisible();
    }

    final elbowAngle = _angle(lShoulder, lElbow, lWrist);
    final isUp       = elbowAngle < 90;
    int   score      = 0;
    final feedback   = <String>[];

    // Top position
    if (elbowAngle < 80) {
      score += 35;
      feedback.add('✅ Great height!');
    } else if (isUp) {
      score += 20;
      feedback.add('⚠️ Pull higher');
    }

    // Body swing
    if (lHip != null) {
      final swing = (lHip.x - lShoulder.x).abs();
      if (swing < 30) {
        score += 35;
        feedback.add('✅ No kipping');
      } else {
        feedback.add('⚠️ Reduce swinging');
      }
    } else {
      score += 30;
    }

    score += 30;

    return FormResult(
      score:    score.clamp(0, 100),
      feedback: feedback,
      phase:    isUp ? '⬆️ Up' : '⬇️ Down',
      isDown:   !isUp,
    );
  }

  FormResult _analyseGeneral(Pose pose) {
    return FormResult(
      score:    75,
      feedback: ['✅ Keep going!', '📐 Focus on form'],
      phase:    'Moving',
      isDown:   false,
    );
  }

  // ── Angle Math ────────────────────────────────────────────
  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x)
                  - atan2(a.y - b.y, a.x - b.x);
    double angle  = radians * 180 / pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  // ── Score Color ───────────────────────────────────────────
  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.accent;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── Camera Feed ──────────────────────────────────
          if (_cameraReady && _cameraCtrl != null)
            Positioned.fill(
              child: CameraPreview(_cameraCtrl!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent)),

          // ── Pose Skeleton Overlay ────────────────────────
          if (_currentPose != null && _cameraCtrl != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                  pose:        _currentPose!,
                  imageSize:   Size(
                    _cameraCtrl!.value.previewSize!.height,
                    _cameraCtrl!.value.previewSize!.width,
                  ),
                  screenSize:  MediaQuery.of(context).size,
                  scoreColor:  _scoreColor(_formScore),
                ),
              ),
            ),

          // ── Top Bar ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  ),
                  // Rep counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_repCount reps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  ),
                ]),
              ),
            ),
          ),

          // ── Phase Label ──────────────────────────────────
          Positioned(
            top: 100,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_phase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              ),
            ),
          ),

          // ── Bottom Score Panel ───────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Score bar
                  Row(children: [
                    Text('FORM',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _formScore / 100,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                            _scoreColor(_formScore)),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$_formScore',
                      style: TextStyle(
                        color: _scoreColor(_formScore),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      )),
                  ]),

                  const SizedBox(height: 16),

                  // Feedback chips
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _feedback.map((f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(f,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        )),
                    )).toList(),
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

// ═══════════════════════════════════════════════════════════
// FORM RESULT MODEL
// ═══════════════════════════════════════════════════════════

class FormResult {
  final int         score;
  final List<String> feedback;
  final String      phase;
  final bool        isDown;

  FormResult({
    required this.score,
    required this.feedback,
    required this.phase,
    required this.isDown,
  });

  factory FormResult.notVisible() => FormResult(
    score:    0,
    feedback: ['👤 Stand in frame'],
    phase:    'Detecting...',
    isDown:   false,
  );
}

// ═══════════════════════════════════════════════════════════
// POSE PAINTER — draws skeleton overlay
// ═══════════════════════════════════════════════════════════

class PosePainter extends CustomPainter {
  final Pose      pose;
  final Size      imageSize;
  final Size      screenSize;
  final Color     scoreColor;

  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
    required this.scoreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final jointPaint = Paint()
      ..color     = scoreColor
      ..strokeWidth = 8
      ..style     = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color     = scoreColor.withOpacity(0.7)
      ..strokeWidth = 3
      ..style     = PaintingStyle.stroke;

    // Draw bones (connections)
    final connections = [
      // Torso
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip],
      // Left arm
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow,     PoseLandmarkType.leftWrist],
      // Right arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist],
      // Left leg
      [PoseLandmarkType.leftHip,       PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee,      PoseLandmarkType.leftAnkle],
      // Right leg
      [PoseLandmarkType.rightHip,      PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee,     PoseLandmarkType.rightAnkle],
    ];

    for (final conn in connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a != null && b != null) {
        canvas.drawLine(
          _translate(a, size),
          _translate(b, size),
          bonePaint,
        );
      }
    }

    // Draw joints
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > 0.5) {
        canvas.drawCircle(_translate(landmark, size), 6, jointPaint);
      }
    }
  }

  Offset _translate(PoseLandmark landmark, Size size) {
    return Offset(
      landmark.x / imageSize.width  * size.width,
      landmark.y / imageSize.height * size.height,
    );
  }

  @override
  bool shouldRepaint(PosePainter old) => old.pose != pose;
}