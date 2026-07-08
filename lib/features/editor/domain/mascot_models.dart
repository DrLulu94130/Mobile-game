/// The 3D poses available in the pose booth.
///
/// To add a pose: drop the .glb file into `assets/models/` and add its path
/// here — the booth shows one chip per entry automatically.
const List<({String label, String asset})> kMascotPoses = [
  (label: 'Classic', asset: 'assets/models/chameleon.glb'),
  (label: 'Pose 2', asset: 'assets/models/chameleon_pose_02.glb'),
  (label: 'Pose 5', asset: 'assets/models/chameleon_pose_05.glb'),
  (label: 'Pose 17', asset: 'assets/models/chameleon_pose_17.glb'),
  (label: 'Pose 19', asset: 'assets/models/chameleon_pose_19.glb'),
];
