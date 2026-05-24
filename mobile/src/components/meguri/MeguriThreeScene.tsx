import type { ExpoWebGLRenderingContext } from "expo-gl";
import { Asset } from "expo-asset";
import type { ComponentType, ReactNode } from "react";
import {
  Component,
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";
import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from "react-native";
import * as THREE from "three";
import { GLTFLoader, type GLTF } from "three/examples/jsm/loaders/GLTFLoader.js";
import * as SkeletonUtils from "three/examples/jsm/utils/SkeletonUtils.js";
import type {
  MeguriAnimalType,
  MeguriFurColor,
  MeguriHue,
} from "../../../app/(tabs)/encounters";
import { ihubColors } from "../../theme/tokens";

export type MeguriSceneMode =
  | "summary"
  | "approaching"
  | "dialogue"
  | "exiting"
  | "done";
export type MeguriIntroPhase = "camera" | "splash" | "walking" | "ready";

export type MeguriSceneResident = {
  animalType: MeguriAnimalType;
  furColor: MeguriFurColor;
  hue: MeguriHue;
  id: string;
  name: string;
};

type MeguriThreeSceneProps = {
  activeId: string | null;
  completedIds: string[];
  introPhase?: MeguriIntroPhase;
  mode: MeguriSceneMode;
  onUnavailable?: () => void;
  presentation?: "home" | "intro" | "plaza" | "profile";
  residents: MeguriSceneResident[];
  self: MeguriSceneResident;
  focusedId?: string | null;
  smilingId?: string | null;
  speakingId?: string | null;
  speaking?: boolean;
  wavingId?: string | null;
};

type MeguriThreeBoundaryProps = {
  children: ReactNode;
  fallback: ReactNode;
  onError?: () => void;
};

type MeguriThreeBoundaryState = {
  failed: boolean;
};

type ExpoGLModule = {
  GLView: ComponentType<{
    msaaSamples?: number;
    onContextCreate: (gl: ExpoWebGLRenderingContext) => void;
    style?: StyleProp<ViewStyle>;
  }>;
};

let cachedGLView: ExpoGLModule["GLView"] | null | undefined;
const avatarAssetModules: Record<MeguriAnimalType, number> = {
  cat: require("../../../assets/meguri-avatars/cat.glb"),
  fox: require("../../../assets/meguri-avatars/fox.glb"),
  rabbit: require("../../../assets/meguri-avatars/rabbit.glb"),
};
const avatarTextureAssetModules: Record<MeguriAnimalType, number> = {
  cat: require("../../../assets/meguri-avatars/textures/cat-v2.png"),
  fox: require("../../../assets/meguri-avatars/textures/fox-v2.png"),
  rabbit: require("../../../assets/meguri-avatars/textures/rabbit-v2.png"),
};
const avatarTextureSize: Record<MeguriAnimalType, { height: number; width: number }> = {
  cat: { height: 2048, width: 2048 },
  fox: { height: 2048, width: 2048 },
  rabbit: { height: 2048, width: 2048 },
};
const AVATAR_MODEL_TARGET_HEIGHT = 0.0432;
const avatarTemplateCache = new Map<MeguriAnimalType, Promise<THREE.Group>>();
const avatarTextureCache = new Map<MeguriAnimalType, Promise<THREE.Texture>>();

function getExpoGLView() {
  if (cachedGLView !== undefined) return cachedGLView;
  try {
    cachedGLView = (require("expo-gl") as ExpoGLModule).GLView;
  } catch {
    cachedGLView = null;
  }
  return cachedGLView;
}

type SceneSnapshot = {
  activeId: string | null;
  completedIds: string[];
  introPhase: MeguriIntroPhase;
  mode: MeguriSceneMode;
  residents: MeguriSceneResident[];
  presentation: "home" | "intro" | "plaza" | "profile";
  self: MeguriSceneResident;
  focusedId: string | null;
  smilingId: string | null;
  speakingId: string | null;
  speaking: boolean;
  wavingId: string | null;
};

type ResidentRuntime = {
  group: THREE.Group;
  motionRole: ResidentRole | null;
  parts: PlushParts;
  resident: MeguriSceneResident;
  roleStartedAt: number;
  spawnPosition: THREE.Vector3;
};

type SkeletonUtilsModule = {
  clone?: (source: THREE.Object3D) => THREE.Object3D;
};

type PlushModel = {
  group: THREE.Group;
  parts: PlushParts;
};

type PlushParts = {
  body: THREE.Object3D;
  face: FaceTextureState;
  head: THREE.Object3D;
  leftArm: THREE.Object3D;
  leftFoot: THREE.Object3D;
  leftLeg: THREE.Object3D;
  rightArm: THREE.Object3D;
  rightFoot: THREE.Object3D;
  rightLeg: THREE.Object3D;
  tail: THREE.Object3D;
};

type FaceTextureState = {
  baseData: Uint8Array;
  data: Uint8Array;
  height: number;
  kind: MeguriAnimalType;
  accent: readonly [number, number, number, number];
  ink: readonly [number, number, number, number];
  lastMouthFrame: number;
  texture: THREE.DataTexture;
  white: readonly [number, number, number, number];
  width: number;
};

type ThreeRuntime = {
  camera: THREE.PerspectiveCamera;
  cameraLookAt: THREE.Vector3;
  clock: THREE.Clock;
  clouds: THREE.Group[];
  disposed: boolean;
  frameId: number | null;
  renderer: THREE.WebGLRenderer;
  residentGroups: Map<string, ResidentRuntime>;
  scene: THREE.Scene;
  selfGroup: ResidentRuntime;
  world: THREE.Group;
};

type ResidentRole =
  | "active"
  | "exiting"
  | "farewell"
  | "home_row"
  | "intro_queue"
  | "plaza"
  | "profile"
  | "queue"
  | "self"
  | "self_gate";

type ResidentTarget = {
  bob: number;
  bobSpeed: number;
  position: THREE.Vector3;
  rotationY: number;
  scale: THREE.Vector3;
  speed: number;
  sway: number;
};

export class MeguriThreeBoundary extends Component<
  MeguriThreeBoundaryProps,
  MeguriThreeBoundaryState
> {
  state: MeguriThreeBoundaryState = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  componentDidCatch() {
    this.props.onError?.();
  }

  render() {
    if (this.state.failed) return this.props.fallback;
    return this.props.children;
  }
}

const furColors: Record<MeguriFurColor, string> = {
  cocoa: "#b78b70",
  cream: "#f0dfbd",
  gray: "#bfc3cb",
  lavender: "#b8a9e6",
  mint: "#a7d9c7",
  pink: "#f2b8cb",
  sky: "#a9d9ed",
};

const hueColors: Record<MeguriHue, string> = {
  butter: "#efd99b",
  lav: ihubColors.lavender,
  mint: "#a8dcc9",
  pink: ihubColors.pink,
  sky: ihubColors.sky,
};

export function MeguriThreeScene({
  activeId,
  completedIds,
  introPhase = "ready",
  mode,
  onUnavailable,
  presentation = "intro",
  residents,
  self,
  focusedId = null,
  smilingId = null,
  speaking = false,
  speakingId = null,
  wavingId = null,
}: MeguriThreeSceneProps) {
  const [failed, setFailed] = useState(false);
  const RuntimeGLView = getExpoGLView();
  const snapshotRef = useRef<SceneSnapshot>({
    activeId,
    completedIds,
    introPhase,
    mode,
    presentation,
    residents,
    self,
    focusedId,
    smilingId,
    speaking,
    speakingId,
    wavingId,
  });
  const runtimeRef = useRef<ThreeRuntime | null>(null);

  useEffect(() => {
    snapshotRef.current = {
      activeId,
      completedIds,
      introPhase,
      mode,
      presentation,
      residents,
      self,
      focusedId,
      smilingId,
      speaking,
      speakingId,
      wavingId,
    };
  }, [
    activeId,
    completedIds,
    introPhase,
    mode,
    presentation,
    residents,
    self,
    focusedId,
    smilingId,
    speaking,
    speakingId,
    wavingId,
  ]);

  useEffect(() => {
    return () => {
      disposeRuntime(runtimeRef.current);
      runtimeRef.current = null;
    };
  }, []);

  const handleContextCreate = useCallback(
    (gl: ExpoWebGLRenderingContext) => {
      try {
        const runtime = createRuntime(gl, snapshotRef.current);
        runtimeRef.current = runtime;

        const tick = () => {
          if (runtime.disposed) return;
          const delta = runtime.clock.getDelta();
          updateRuntime(runtime, snapshotRef.current, delta);
          runtime.renderer.render(runtime.scene, runtime.camera);
          gl.endFrameEXP();
          runtime.frameId = requestAnimationFrame(tick);
        };

        tick();
      } catch {
        setFailed(true);
        onUnavailable?.();
      }
    },
    [onUnavailable],
  );

  if (failed || !RuntimeGLView) {
    return (
      <View style={styles.failed}>
        <Text style={styles.failedTitle}>3Dを準備できませんでした</Text>
        <Text style={styles.failedText}>2D表示に切り替えます</Text>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <RuntimeGLView
        msaaSamples={4}
        onContextCreate={handleContextCreate}
        style={styles.glView}
      />
      {presentation === "intro" ? (
        <View pointerEvents="none" style={styles.depthLabel}>
          <Text style={styles.depthLabelText}>3D MEGURI</Text>
        </View>
      ) : null}
    </View>
  );
}

function createRuntime(
  gl: ExpoWebGLRenderingContext,
  snapshot: SceneSnapshot,
): ThreeRuntime {
  const width = gl.drawingBufferWidth;
  const height = gl.drawingBufferHeight;
  const renderer = createRenderer(gl, width, height);
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(
    snapshot.presentation === "home" || snapshot.presentation === "plaza" || snapshot.presentation === "profile"
      ? "#c9f1ff"
      : "#bdefff",
  );

  const camera = new THREE.PerspectiveCamera(58, width / height, 0.1, 100);
  const openingCamera =
    snapshot.mode === "summary" && snapshot.introPhase === "camera";
  if (snapshot.presentation === "home") {
    camera.position.set(0, 1.82, 5.25);
    camera.lookAt(0, 0.64, 0.46);
  } else if (snapshot.presentation === "plaza") {
    camera.fov = 46;
    camera.updateProjectionMatrix();
    camera.position.set(0, 6.9, 5.45);
    camera.lookAt(0, 0.04, -0.04);
  } else if (snapshot.presentation === "profile") {
    camera.position.set(0, 2.55, 5.05);
    camera.lookAt(0, 0.86, 0.02);
  } else if (openingCamera) {
    camera.position.set(-1.64, 7.4, 5.72);
    camera.lookAt(-1.64, 0.7, -0.42);
  } else {
    camera.position.set(0, 2.35, 8.35);
    camera.lookAt(-0.1, 0.68, 0.05);
  }

  scene.add(new THREE.AmbientLight(0xffffff, 1.35));
  scene.add(new THREE.HemisphereLight("#fff7df", "#b9ddc3", 1.15));

  const keyLight = new THREE.DirectionalLight(0xffffff, 0.62);
  keyLight.position.set(-2.5, 4.5, 4);
  scene.add(keyLight);

  const fillLight = new THREE.DirectionalLight("#e9fbff", 0.42);
  fillLight.position.set(3.2, 3.5, 3.5);
  scene.add(fillLight);

  const warmLight = new THREE.PointLight("#fff7df", 4.2, 8);
  warmLight.position.set(-1.8, 2.9, 2.0);
  scene.add(warmLight);

  const world = new THREE.Group();
  world.position.set(0, -0.38, 0);
  scene.add(world);
  const plaza = createPlazaSet();
  world.add(plaza.group);

  const selfGroup = createResidentRuntime(snapshot.self);
  const selfTarget = getResidentTarget(openingCamera ? "self_gate" : "self", 0, 1);
  selfGroup.group.position.copy(selfTarget.position);
  selfGroup.group.rotation.y = selfTarget.rotationY;
  selfGroup.group.scale.copy(selfTarget.scale);
  world.add(selfGroup.group);

  const residentGroups = new Map<string, ResidentRuntime>();
  for (const [index, resident] of snapshot.residents.entries()) {
    const runtime = createResidentRuntime(resident, index);
    residentGroups.set(resident.id, runtime);
    world.add(runtime.group);
  }

  return {
    camera,
    cameraLookAt:
      snapshot.presentation === "home"
        ? new THREE.Vector3(0, 0.64, 0.46)
        : snapshot.presentation === "plaza"
          ? new THREE.Vector3(0, 0.04, -0.04)
          : snapshot.presentation === "profile"
            ? new THREE.Vector3(0, 0.86, 0.02)
          : openingCamera
            ? new THREE.Vector3(-1.64, 0.7, -0.42)
            : new THREE.Vector3(-0.1, 0.68, 0.05),
    clock: new THREE.Clock(),
    clouds: plaza.clouds,
    disposed: false,
    frameId: null,
    renderer,
    residentGroups,
    scene,
    selfGroup,
    world,
  };
}

function createRenderer(
  gl: ExpoWebGLRenderingContext,
  width: number,
  height: number,
) {
  const canvasShim = {
    addEventListener: () => undefined,
    clientHeight: height,
    clientWidth: width,
    height,
    removeEventListener: () => undefined,
    style: {},
    width,
  } as unknown as HTMLCanvasElement;

  const renderer = new THREE.WebGLRenderer({
    antialias: true,
    canvas: canvasShim,
    context: gl as unknown as WebGLRenderingContext,
  });
  renderer.setPixelRatio(1);
  renderer.setSize(width, height, false);
  renderer.setClearColor("#bdefff", 1);
  return renderer;
}

function updateRuntime(
  runtime: ThreeRuntime,
  snapshot: SceneSnapshot,
  delta: number,
) {
  const elapsed = runtime.clock.elapsedTime;
  if (snapshot.presentation === "home" || snapshot.presentation === "plaza" || snapshot.presentation === "profile") {
    animateClouds(runtime.clouds, delta);
    updateCameraFocus(runtime, snapshot, delta);
    runtime.selfGroup.group.visible = false;
    const role =
      snapshot.presentation === "profile"
        ? "profile"
        : snapshot.presentation === "plaza"
          ? "plaza"
          : "home_row";

    for (const [index, resident] of snapshot.residents.entries()) {
      if (!runtime.residentGroups.has(resident.id)) {
        const created = createResidentRuntime(resident, index);
        runtime.residentGroups.set(resident.id, created);
        runtime.world.add(created.group);
      }

      const item = runtime.residentGroups.get(resident.id);
      if (!item) continue;
      syncResidentVisual(item, resident);
      item.group.visible = snapshot.presentation !== "profile" || index === 0;
      if (!item.group.visible) continue;
      const focused =
        (snapshot.presentation === "plaza" || snapshot.presentation === "profile") &&
        snapshot.focusedId === resident.id;
      updateResidentObject(
        item,
        role,
        index,
        snapshot.residents.length,
        elapsed,
        delta,
        snapshot.speaking && snapshot.speakingId === resident.id,
        focused || snapshot.smilingId === resident.id,
      );
      if (focused) {
        const focusStep = Math.min(1, delta * 4.4);
        item.group.rotation.y = THREE.MathUtils.lerp(item.group.rotation.y, 0, focusStep);
        const focusScale = getResidentTarget(role, index, snapshot.residents.length).scale
          .clone()
          .multiplyScalar(1.12);
        item.group.scale.lerp(focusScale, focusStep);
      }
    }
    return;
  }

  const completed = new Set(snapshot.completedIds);
  const queued = snapshot.residents.filter(
    (resident) =>
      !completed.has(resident.id) &&
      resident.id !== snapshot.activeId &&
      snapshot.mode !== "done",
  );

  animateClouds(runtime.clouds, delta);
  updateCameraFocus(runtime, snapshot, delta);
  syncResidentVisual(runtime.selfGroup, snapshot.self);
  const selfRole =
    snapshot.mode === "summary" &&
    (snapshot.introPhase === "camera" || snapshot.introPhase === "splash")
      ? "self_gate"
      : "self";
  updateResidentObject(
    runtime.selfGroup,
    selfRole,
    0,
    1,
    elapsed,
    delta,
    snapshot.speaking && snapshot.speakingId === snapshot.self.id,
    snapshot.smilingId === snapshot.self.id,
  );

  for (const resident of snapshot.residents) {
    if (!runtime.residentGroups.has(resident.id)) {
      const created = createResidentRuntime(
        resident,
        snapshot.residents.findIndex((item) => item.id === resident.id),
      );
      runtime.residentGroups.set(resident.id, created);
      runtime.world.add(created.group);
    }

    const item = runtime.residentGroups.get(resident.id);
    if (!item) continue;
    syncResidentVisual(item, resident);

    if (snapshot.mode === "done") {
      item.group.visible = false;
      continue;
    }

    if (resident.id === snapshot.activeId) {
      const role =
        snapshot.mode === "exiting"
          ? "exiting"
          : snapshot.wavingId === resident.id
            ? "farewell"
            : "active";
      item.group.visible = true;
      updateResidentObject(
        item,
        role,
        0,
        1,
        elapsed,
        delta,
        snapshot.speaking && snapshot.speakingId === resident.id,
        snapshot.smilingId === resident.id,
      );
      continue;
    }

    if (completed.has(resident.id)) {
      item.group.visible = false;
      continue;
    }

    const queueIndex = queued.findIndex((queuedResident) => queuedResident.id === resident.id);
    item.group.visible = queueIndex >= 0;
    if (queueIndex >= 0) {
      const role = snapshot.mode === "summary" && snapshot.introPhase !== "ready"
        ? "intro_queue"
        : "queue";
      updateResidentObject(
        item,
        role,
        queueIndex,
        queued.length,
        elapsed,
        delta,
        snapshot.speaking && snapshot.speakingId === resident.id,
        snapshot.smilingId === resident.id,
      );
    }
  }
}

function syncResidentVisual(
  item: ResidentRuntime,
  resident: MeguriSceneResident,
) {
  if (
    item.resident.animalType === resident.animalType &&
    item.resident.furColor === resident.furColor &&
    item.resident.hue === resident.hue
  ) {
    item.resident = resident;
    return;
  }

  const plush = createPlushAnimal(resident);
  item.group.clear();
  item.group.userData.avatarMixer = null;
  item.group.userData.avatarActions = [];
  item.group.add(plush.group);
  item.parts = plush.parts;
  item.resident = resident;
}

function updateResidentObject(
  item: ResidentRuntime,
  role: ResidentRole,
  index: number,
  total: number,
  elapsed: number,
  delta: number,
  speaking = false,
  smiling = false,
) {
  if (item.motionRole !== role) {
    item.motionRole = role;
    item.roleStartedAt = elapsed;
  }

  const roleElapsed = elapsed - item.roleStartedAt;
  let target = getResidentTarget(role, index, total);
  const exitTurning = role === "exiting" && roleElapsed < 0.62;
  if (exitTurning) {
    target = {
      ...target,
      bob: 0,
      position: new THREE.Vector3(item.group.position.x, 0, item.group.position.z),
      scale: item.group.scale.clone(),
      speed: 5.4,
      sway: 0,
    };
  }
  const step = Math.min(1, delta * target.speed);
  const distance = item.group.position.distanceTo(target.position);
  const moving =
    !exitTurning &&
    (role === "exiting" ||
      (role !== "self_gate" && distance > 0.06));
  const bobWave = Math.sin(elapsed * target.bobSpeed + index * 0.7);
  const idleBob =
    role === "active" ||
    role === "farewell" ||
    role === "self" ||
    role === "self_gate" ||
    role === "queue"
      ? target.bob * 0.18
      : 0;
  const bob = moving
    ? Math.max(0, bobWave) * target.bob
    : Math.max(0, bobWave) * idleBob;
  const sway = moving ? Math.sin(elapsed * target.bobSpeed + index) * target.sway : 0;
  const idleSideSway =
    !moving &&
    (role === "home_row" ||
      role === "plaza" ||
      role === "queue" ||
      role === "self" ||
      role === "self_gate" ||
      role === "active" ||
      role === "farewell")
      ? Math.sin(elapsed * target.bobSpeed * 0.42 + index * 0.8) * target.sway
      : 0;

  item.group.position.lerp(target.position, step);
  item.group.position.y = target.position.y + bob;
  item.group.position.x += idleSideSway * 0.18;
  item.group.scale.lerp(target.scale, step);
  item.group.rotation.y = THREE.MathUtils.lerp(
    item.group.rotation.y,
    target.rotationY,
    step,
  );
  item.group.rotation.z = moving ? sway : idleSideSway;
  animatePlushParts(item, role, target, elapsed, index, moving);
  animateFace(item.parts.face, speaking, smiling, elapsed);
}

function updateCameraFocus(
  runtime: ThreeRuntime,
  snapshot: SceneSnapshot,
  delta: number,
) {
  const focus = getCameraFocusTarget(snapshot);
  const speed =
    snapshot.mode === "summary" && snapshot.introPhase === "camera" ? 0.58 : 1.35;
  const step = Math.min(1, delta * speed);
  runtime.camera.position.lerp(focus.position, step);
  runtime.cameraLookAt.lerp(focus.lookAt, step);
  runtime.camera.lookAt(runtime.cameraLookAt);
}

function getCameraFocusTarget(snapshot: SceneSnapshot) {
  if (snapshot.presentation === "home") {
    return {
      lookAt: new THREE.Vector3(0, 0.64, 0.46),
      position: new THREE.Vector3(0, 1.82, 5.25),
    };
  }

  if (snapshot.presentation === "plaza") {
    return {
      lookAt: new THREE.Vector3(0, 0.04, -0.04),
      position: new THREE.Vector3(0, 6.9, 5.45),
    };
  }

  if (snapshot.presentation === "profile") {
    return {
      lookAt: new THREE.Vector3(0, 0.86, 0.02),
      position: new THREE.Vector3(0, 2.55, 5.05),
    };
  }

  if (snapshot.mode === "summary" && snapshot.introPhase === "camera") {
    return {
      lookAt: new THREE.Vector3(-1.64, 0.7, -0.42),
      position: new THREE.Vector3(-1.64, 2.35, 5.72),
    };
  }

  if (snapshot.mode === "summary" && snapshot.introPhase === "splash") {
    return {
      lookAt: new THREE.Vector3(-1.92, 0.74, -0.52),
      position: new THREE.Vector3(-1.48, 2.42, 6.3),
    };
  }

  if (snapshot.mode === "dialogue" && snapshot.speakingId === snapshot.self.id) {
    return {
      lookAt: new THREE.Vector3(-1.08, 0.82, 0.62),
      position: new THREE.Vector3(-0.56, 2.32, 8.05),
    };
  }

  if (snapshot.mode === "dialogue" && snapshot.speakingId === snapshot.activeId) {
    return {
      lookAt: new THREE.Vector3(0.18, 0.8, 0.62),
      position: new THREE.Vector3(0.38, 2.32, 8.05),
    };
  }

  return {
    lookAt: new THREE.Vector3(-0.1, 0.68, 0.05),
    position: new THREE.Vector3(0, 2.35, 8.35),
  };
}

function animateClouds(clouds: THREE.Group[], delta: number) {
  for (const cloud of clouds) {
    const speed =
      typeof cloud.userData.speed === "number" ? cloud.userData.speed : 0.08;
    cloud.position.x += speed * delta;
    if (cloud.position.x > 4.75) {
      cloud.position.x = -4.85;
    }
  }
}

function getResidentTarget(
  role: ResidentRole,
  index: number,
  total: number,
): ResidentTarget {
  if (role === "self") {
    return {
      bob: 0.025,
      bobSpeed: 2.4,
      position: new THREE.Vector3(-1.48, 0, 0.72),
      rotationY: 0.62,
      scale: new THREE.Vector3(0.82, 0.82, 0.82),
      speed: 7.2,
      sway: 0.018,
    };
  }

  if (role === "self_gate") {
    return {
      bob: 0.018,
      bobSpeed: 2.1,
      position: new THREE.Vector3(-2.05, 0, -0.34),
      rotationY: 0.18,
      scale: new THREE.Vector3(0.82, 0.82, 0.82),
      speed: 7,
      sway: 0.012,
    };
  }

  if (role === "active") {
    return {
      bob: 0.04,
      bobSpeed: 3.6,
      position: new THREE.Vector3(0.2, 0, 0.72),
      rotationY: -0.45,
      scale: new THREE.Vector3(0.96, 0.96, 0.96),
      speed: 7.4,
      sway: 0.032,
    };
  }

  if (role === "farewell") {
    return {
      bob: 0.04,
      bobSpeed: 3.2,
      position: new THREE.Vector3(0.2, 0, 0.72),
      rotationY: -0.45,
      scale: new THREE.Vector3(0.96, 0.96, 0.96),
      speed: 7.4,
      sway: 0.024,
    };
  }

  if (role === "exiting") {
    return {
      bob: 0.06,
      bobSpeed: 4.4,
      position: new THREE.Vector3(-4.35, 0, -2.42),
      rotationY: -2.18,
      scale: new THREE.Vector3(0.26, 0.26, 0.26),
      speed: 1.18,
      sway: 0.06,
    };
  }

  if (role === "home_row") {
    const center = (Math.max(total, 1) - 1) / 2;
    const offset = index - center;
    const distance = Math.abs(offset);
    const scale = Math.max(0.52, 0.74 - distance * 0.035);
    return {
      bob: 0.026,
      bobSpeed: 2.15,
      position: new THREE.Vector3(offset * 0.72, 0, 0.74 - distance * 0.08),
      rotationY: offset * 0.08,
      scale: new THREE.Vector3(scale, scale, scale),
      speed: 5.8,
      sway: 0.014,
    };
  }

  if (role === "plaza") {
    const plazaSpots = [
      [-2.25, -1.65, 0.54],
      [-0.75, -1.85, 0.59],
      [0.72, -1.75, 0.59],
      [2.1, -1.45, 0.54],
      [-1.75, -0.25, 0.61],
      [-0.18, -0.08, 0.66],
      [1.45, -0.22, 0.61],
      [-1.12, 1.28, 0.58],
      [0.46, 1.52, 0.6],
      [1.92, 1.18, 0.55],
      [-2.25, 1.02, 0.52],
      [2.32, 0.38, 0.5],
    ] as const;
    const [x, z, scale] = plazaSpots[index % plazaSpots.length] ?? [0, 0, 0.64];
    const row = Math.floor(index / plazaSpots.length);
    const tuckedScale = Math.max(0.42, scale - row * 0.08);
    return {
      bob: 0.026,
      bobSpeed: 2.05 + (index % 3) * 0.12,
      position: new THREE.Vector3(x, 0, z - row * 0.42),
      rotationY: -0.02 + (index - (total - 1) / 2) * 0.025,
      scale: new THREE.Vector3(tuckedScale, tuckedScale, tuckedScale),
      speed: 5.4,
      sway: 0.028,
    };
  }

  if (role === "profile") {
    return {
      bob: 0.03,
      bobSpeed: 2.3,
      position: new THREE.Vector3(0, 0, 0.42),
      rotationY: 0,
      scale: new THREE.Vector3(1.02, 1.02, 1.02),
      speed: 6.2,
      sway: 0.02,
    };
  }

  const safeTotal = Math.max(total, 1);
  const depth = Math.min(index, 8);
  const x = 1.03 + Math.min(depth, 5) * 0.16;
  const z = 0.68 - depth * 0.34;
  const scale = Math.max(0.38, 0.66 - depth * 0.035);

  if (role === "intro_queue") {
    return {
      bob: 0.038,
      bobSpeed: 2.65,
      position: new THREE.Vector3(x, 0, z),
      rotationY: -0.34 + (safeTotal > 5 ? 0.06 : 0),
      scale: new THREE.Vector3(scale, scale, scale),
      speed: 0.54,
      sway: 0.026,
    };
  }

  return {
    bob: 0.018,
    bobSpeed: 1.8,
    position: new THREE.Vector3(x, 0, z),
    rotationY: -0.34 + (safeTotal > 5 ? 0.06 : 0),
    scale: new THREE.Vector3(scale, scale, scale),
    speed: 6.8,
    sway: 0.012,
  };
}

function placeAtSpawn(item: ResidentRuntime, elapsed: number) {
  item.group.position.copy(item.spawnPosition);
  item.group.position.y = Math.max(0, Math.sin(elapsed * 2.2)) * 0.012;
  item.group.scale.set(0.18, 0.18, 0.18);
  item.group.rotation.y = -0.28;
  item.group.rotation.z = 0;
  animatePlushParts(item, "queue", getResidentTarget("queue", 0, 1), elapsed, 0);
}

function animatePlushParts(
  item: ResidentRuntime,
  role: ResidentRole,
  target: ResidentTarget,
  elapsed: number,
  index: number,
  walkingOverride?: boolean,
) {
  const distance = item.group.position.distanceTo(target.position);
  const walking =
    walkingOverride ??
    (role === "exiting" ||
      (role !== "self" && role !== "home_row" && role !== "plaza" && distance > 0.08));
  const pace =
    role === "exiting" ? 6.4 : role === "intro_queue" ? 4.8 : role === "queue" ? 8.6 : 7.4;
  const phase = elapsed * pace + index * 0.7;
  const stride = Math.sin(phase);
  const counter = Math.sin(phase + Math.PI);

  if (!walking) {
    const idle =
      role === "self" || role === "self_gate" || role === "active"
        ? 0.08
        : role === "plaza"
          ? 0.07
        : role === "farewell"
          ? 0.1
          : 0.045;
    const breathe = Math.sin(phase * 0.22 + index * 0.4);
    const softWave = Math.sin(phase * 0.7);
    item.parts.leftArm.rotation.x = breathe * idle * 0.24;
    item.parts.rightArm.rotation.x =
      role === "farewell" ? -0.52 + softWave * 0.34 : -breathe * idle * 0.24;
    item.parts.leftArm.rotation.z = -0.44 + breathe * idle * 0.2;
    item.parts.rightArm.rotation.z =
      role === "farewell" ? -0.92 + softWave * 0.18 : 0.44 - breathe * idle * 0.2;
    item.parts.leftLeg.rotation.x = 0;
    item.parts.rightLeg.rotation.x = 0;
    item.parts.leftLeg.rotation.z = -0.08;
    item.parts.rightLeg.rotation.z = 0.08;
    item.parts.leftFoot.rotation.x = -0.04;
    item.parts.rightFoot.rotation.x = -0.04;
    item.parts.body.rotation.z = Math.sin(phase * 0.28) * idle;
    item.parts.body.rotation.x = Math.sin(phase * 0.18 + 0.4) * idle * 0.18;
    item.parts.head.rotation.z = Math.sin(phase * 0.32) * idle;
    item.parts.head.rotation.x = Math.sin(phase * 0.2 + 0.8) * idle * 0.22;
    item.parts.tail.rotation.y = Math.sin(phase * 0.38) * idle;
    return;
  }

  const intensity = 1;

  item.parts.leftArm.rotation.x = -stride * 0.46 * intensity;
  item.parts.rightArm.rotation.x = -counter * 0.46 * intensity;
  item.parts.leftArm.rotation.z = -0.34 + stride * 0.1 * intensity;
  item.parts.rightArm.rotation.z = 0.34 + counter * 0.1 * intensity;

  item.parts.leftLeg.rotation.x = stride * 0.58 * intensity;
  item.parts.rightLeg.rotation.x = counter * 0.58 * intensity;
  item.parts.leftLeg.rotation.z = -0.08;
  item.parts.rightLeg.rotation.z = 0.08;
  item.parts.leftFoot.rotation.x = -0.08 + Math.max(0, -stride) * 0.32 * intensity;
  item.parts.rightFoot.rotation.x = -0.08 + Math.max(0, -counter) * 0.32 * intensity;

  item.parts.body.rotation.x = 0;
  item.parts.body.rotation.z = Math.sin(phase * 0.5) * 0.025 * intensity;
  item.parts.head.rotation.x = 0;
  item.parts.head.rotation.z = Math.sin(phase * 0.5) * 0.04 * intensity;
  item.parts.tail.rotation.y = Math.sin(phase * 0.8) * 0.42 * intensity;
}

function animateFace(
  face: FaceTextureState,
  speaking: boolean,
  smiling: boolean,
  elapsed: number,
) {
  const pulse = speaking ? Math.abs(Math.sin(elapsed * 18)) : 0;
  const openness = speaking ? Math.max(0.24, pulse) : 0;
  const frame = Math.round(openness * 10) + (smiling ? 100 : 0);
  if (frame === face.lastMouthFrame) return;

  face.data.set(face.baseData);
  drawEyes(
    face.data,
    face.width,
    face.height,
    face.kind,
    smiling,
    face.accent,
    face.ink,
    face.white,
  );
  drawMouth(face.data, face.width, face.height, openness, face.ink);
  face.texture.needsUpdate = true;
  face.lastMouthFrame = frame;
}

function getSpawnPosition(index: number) {
  const depth = Math.min(Math.max(index, 0), 8);
  return new THREE.Vector3(2.65 + depth * 0.14, 0, -3.1 - depth * 0.18);
}

function createResidentRuntime(
  resident: MeguriSceneResident,
  index = 0,
): ResidentRuntime {
  const group = new THREE.Group();
  const spawnPosition = getSpawnPosition(index);
  const plush = createPlushAnimal(resident);
  group.position.copy(spawnPosition);
  group.scale.set(0.18, 0.18, 0.18);
  group.add(plush.group);
  return {
    group,
    motionRole: null,
    parts: plush.parts,
    resident,
    roleStartedAt: 0,
    spawnPosition,
  };
}

function createPlazaSet() {
  const group = new THREE.Group();
  const clouds: THREE.Group[] = [];

  const floorMaterial = new THREE.MeshStandardMaterial({
    color: "#bfecc2",
    roughness: 0.95,
  });
  const floor = new THREE.Mesh(new THREE.CircleGeometry(5.85, 96), floorMaterial);
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = -0.02;
  group.add(floor);

  const center = new THREE.Mesh(
    new THREE.CircleGeometry(3.2, 96),
    new THREE.MeshStandardMaterial({ color: "#fff5d9", roughness: 1 }),
  );
  center.rotation.x = -Math.PI / 2;
  center.position.set(-0.04, 0.002, 0.34);
  center.scale.set(1, 0.64, 1);
  group.add(center);

  const ring = new THREE.Mesh(
    new THREE.RingGeometry(2.9, 2.98, 96),
    new THREE.MeshStandardMaterial({ color: "#8ed89c", roughness: 1 }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.set(-0.04, 0.014, 0.34);
  ring.scale.set(1, 0.64, 1);
  group.add(ring);

  group.add(createPebblePath());
  group.add(createPlazaGate());

  const cloudA = createCloud(-1.65, 3.06, -3.2, 0.82, 0.055);
  const cloudB = createCloud(1.28, 2.8, -3.05, 0.68, 0.04);
  const cloudC = createCloud(3.52, 3.24, -3.35, 0.92, 0.032);
  clouds.push(cloudA, cloudB, cloudC);
  group.add(cloudA);
  group.add(cloudB);
  group.add(cloudC);
  group.add(createSparkle(-1.1, 1.25, -1.0, 0.06));
  group.add(createSparkle(0.55, 1.42, -1.4, 0.05));
  group.add(createSparkle(1.65, 1.08, -0.22, 0.055));
  group.add(createSparkle(-1.52, 0.88, 1.08, 0.05));

  return { clouds, group };
}

function createPlazaGate() {
  const gate = new THREE.Group();
  gate.position.set(-2.18, 0, -1.12);
  gate.rotation.y = 0.28;
  gate.scale.set(1.1, 1.1, 1.1);

  const gateMaterial = new THREE.MeshStandardMaterial({
    color: "#f4e861",
    metalness: 0,
    roughness: 0.82,
  });
  const sideMaterial = new THREE.MeshStandardMaterial({
    color: "#d8cf36",
    metalness: 0,
    roughness: 0.86,
  });
  const innerMaterial = new THREE.MeshStandardMaterial({
    color: "#fff889",
    metalness: 0,
    roughness: 0.82,
  });

  gate.add(createGateArchSlab(sideMaterial, -0.08, 1.04));
  gate.add(createGateArchSlab(gateMaterial, 0.02, 1));
  gate.add(createGateBase(-0.54, sideMaterial));
  gate.add(createGateBase(0.54, sideMaterial));

  const innerArch = new THREE.Mesh(
    new THREE.TorusGeometry(0.42, 0.034, 16, 48, Math.PI),
    innerMaterial,
  );
  innerArch.position.set(0, 1.57, 0.075);
  gate.add(innerArch);

  const sign = new THREE.Mesh(
    new THREE.BoxGeometry(0.74, 0.17, 0.08),
    new THREE.MeshStandardMaterial({ color: "#fff9a8", roughness: 0.9 }),
  );
  sign.position.set(0, 1.08, 0.12);
  gate.add(sign);

  const leaf = new THREE.Mesh(
    new THREE.SphereGeometry(1, 18, 12),
    new THREE.MeshStandardMaterial({ color: "#45b861", roughness: 0.9 }),
  );
  leaf.position.set(-0.14, 2.22, 0.05);
  leaf.rotation.z = -0.62;
  leaf.scale.set(0.14, 0.26, 0.05);
  gate.add(leaf);

  const stem = new THREE.Mesh(
    new THREE.CylinderGeometry(0.018, 0.018, 0.25, 10),
    new THREE.MeshStandardMaterial({ color: "#3d9d55", roughness: 0.9 }),
  );
  stem.position.set(-0.02, 2.08, 0.04);
  stem.rotation.z = -0.45;
  gate.add(stem);

  return gate;
}

function createGateArchSlab(
  material: THREE.Material,
  z: number,
  scale: number,
) {
  const shape = new THREE.Shape();
  shape.moveTo(-0.7, 0);
  shape.lineTo(-0.7, 1.44);
  shape.absarc(0, 1.44, 0.7, Math.PI, 0, true);
  shape.lineTo(0.7, 0);
  shape.lineTo(-0.7, 0);

  const hole = new THREE.Path();
  hole.moveTo(-0.41, 0.08);
  hole.lineTo(-0.41, 1.43);
  hole.absarc(0, 1.43, 0.41, Math.PI, 0, true);
  hole.lineTo(0.41, 0.08);
  hole.lineTo(-0.41, 0.08);
  shape.holes.push(hole);

  const geometry = new THREE.ExtrudeGeometry(shape, {
    bevelEnabled: true,
    bevelSegments: 7,
    bevelSize: 0.022,
    bevelThickness: 0.032,
    depth: 0.16,
  });
  geometry.translate(0, 0, -0.08);

  const arch = new THREE.Mesh(geometry, material);
  arch.position.set(0, 0.04, z);
  arch.scale.set(scale, scale, 1);
  return arch;
}

function createGateBase(x: number, material: THREE.Material) {
  const base = new THREE.Mesh(
    new THREE.BoxGeometry(0.34, 0.16, 0.26),
    material,
  );
  base.position.set(x, 0.02, -0.02);
  return base;
}

function createPebblePath() {
  const group = new THREE.Group();
  const material = new THREE.MeshStandardMaterial({
    color: "#e7ebd4",
    roughness: 1,
  });
  const edgeMaterial = new THREE.MeshStandardMaterial({
    color: "#c9d2b4",
    roughness: 1,
  });

  for (let i = 0; i < 10; i += 1) {
    const stone = new THREE.Mesh(new THREE.CircleGeometry(0.14 + (i % 3) * 0.025, 18), material);
    stone.rotation.x = -Math.PI / 2;
    stone.position.set(-2.0 + i * 0.22, 0.026, -0.92 + i * 0.06);
    stone.scale.set(1.32, 0.72, 1);
    group.add(stone);
  }

  const edge = new THREE.Mesh(new THREE.RingGeometry(0.62, 0.68, 36), edgeMaterial);
  edge.rotation.x = -Math.PI / 2;
  edge.position.set(-1.68, 0.024, -0.7);
  edge.scale.set(1.2, 0.36, 1);
  group.add(edge);
  return group;
}

function createCloud(
  x: number,
  y: number,
  z: number,
  scale: number,
  speed: number,
) {
  const group = new THREE.Group();
  group.position.set(x, y, z);
  group.scale.setScalar(scale);
  group.userData.speed = speed;
  const material = new THREE.MeshBasicMaterial({
    color: "#ffffff",
    opacity: 0.72,
    transparent: true,
  });
  group.add(createSphere([-0.42, 0, 0], [0.62, 0.34, 0.22], material));
  group.add(createSphere([0, 0.08, 0], [0.76, 0.42, 0.24], material));
  group.add(createSphere([0.46, -0.02, 0], [0.54, 0.3, 0.2], material));
  return group;
}

function createSparkle(x: number, y: number, z: number, scale: number) {
  const group = new THREE.Group();
  group.position.set(x, y, z);
  group.scale.setScalar(scale);

  const material = new THREE.MeshStandardMaterial({
    color: "#fff2ad",
    roughness: 0.55,
  });
  const tall = new THREE.Mesh(new THREE.OctahedronGeometry(1, 0), material);
  tall.scale.set(0.32, 1.2, 0.32);
  group.add(tall);

  const wide = new THREE.Mesh(new THREE.OctahedronGeometry(1, 0), material);
  wide.scale.set(1.2, 0.32, 0.32);
  group.add(wide);

  return group;
}

function createPlushAnimal(resident: MeguriSceneResident): PlushModel {
  const group = new THREE.Group();
  const fallbackGroup = new THREE.Group();
  fallbackGroup.name = "procedural-avatar";
  fallbackGroup.visible = false;
  const fur = furColors[resident.furColor];
  const accent = hueColors[resident.hue];
  const furMaterial = new THREE.MeshLambertMaterial({
    color: fur,
  });
  const clothMaterial = new THREE.MeshLambertMaterial({
    color: accent,
  });
  const clothLightMaterial = new THREE.MeshLambertMaterial({
    color: "#fff5d8",
  });

  const body = createSphere([0, 0.48, 0], [0.27, 0.36, 0.22], furMaterial);
  const head = createSphere([0, 1.15, 0.02], [0.74, 0.65, 0.54], furMaterial);
  const tail = createTail(resident.animalType, furMaterial);
  const leftArm = createArm(-1, furMaterial, clothMaterial);
  const rightArm = createArm(1, furMaterial, clothMaterial);
  const leftLeg = createLeg(-1, furMaterial, clothLightMaterial);
  const rightLeg = createLeg(1, furMaterial, clothLightMaterial);
  const leftFoot = leftLeg.getObjectByName("foot") ?? leftLeg;
  const rightFoot = rightLeg.getObjectByName("foot") ?? rightLeg;
  const face = createTexturedFace(resident.animalType, accent);

  fallbackGroup.add(tail);
  fallbackGroup.add(body);
  fallbackGroup.add(createClothes(clothMaterial, clothLightMaterial));
  fallbackGroup.add(leftArm);
  fallbackGroup.add(rightArm);
  fallbackGroup.add(leftLeg);
  fallbackGroup.add(rightLeg);
  fallbackGroup.add(head);
  fallbackGroup.add(createAnimalEars(resident.animalType, furMaterial));
  fallbackGroup.add(face.group);
  fallbackGroup.add(createTufts(furMaterial));
  group.add(fallbackGroup);

  const shadow = new THREE.Mesh(
    new THREE.CircleGeometry(1, 36),
    new THREE.MeshBasicMaterial({
      color: "#574c68",
      opacity: 0.14,
      transparent: true,
    }),
  );
  shadow.position.set(0, 0.005, 0);
  shadow.rotation.x = -Math.PI / 2;
  shadow.scale.set(0.34, 0.24, 1);
  group.add(shadow);
  attachAvatarModel(group, fallbackGroup, resident.animalType);

  return {
    group,
    parts: {
      body,
      face: face.state,
      head,
      leftArm,
      leftFoot,
      leftLeg,
      rightArm,
      rightFoot,
      rightLeg,
      tail,
    },
  };
}

function attachAvatarModel(
  group: THREE.Group,
  fallbackGroup: THREE.Group,
  animalType: MeguriAnimalType,
) {
  const safeAnimalType = normalizeAvatarAnimalType(animalType);
  const loadToken = Symbol(safeAnimalType);
  group.userData.avatarLoadToken = loadToken;
  void loadAvatarTemplate(safeAnimalType)
    .then(async (template) => {
      if (group.userData.avatarLoadToken !== loadToken) return;
      const model = cloneAvatarTemplate(template);
      model.name = `meguri-avatar-${safeAnimalType}`;
      prepareAvatarClone(model);
      await loadAvatarTexture(safeAnimalType)
        .then((texture) => applyAvatarTexture(model, texture))
        .catch(() => applyAvatarFallbackMaterial(model));
      if (group.userData.avatarLoadToken !== loadToken) return;
      fallbackGroup.visible = false;
      group.add(model);
    })
    .catch(() => {
      if (group.userData.avatarLoadToken === loadToken) {
        fallbackGroup.visible = false;
      }
    });
}

function loadAvatarTemplate(animalType: MeguriAnimalType) {
  const safeAnimalType = normalizeAvatarAnimalType(animalType);
  const cached = avatarTemplateCache.get(safeAnimalType);
  if (cached) return cached;

  const promise = Asset.loadAsync(avatarAssetModules[safeAnimalType]).then(
    ([asset]) =>
      new Promise<THREE.Group>((resolve, reject) => {
        const uri = asset.localUri ?? asset.uri;
        if (!uri) {
          reject(new Error(`Missing ${safeAnimalType} avatar asset uri`));
          return;
        }
        const loader = new GLTFLoader();
        loader.load(
          uri,
          (gltf: GLTF) => {
            prepareAvatarMaterials(gltf.scene);
            resolve(gltf.scene);
          },
          undefined,
          reject,
        );
      }),
  );
  avatarTemplateCache.set(safeAnimalType, promise);
  return promise;
}

function loadAvatarTexture(animalType: MeguriAnimalType) {
  const safeAnimalType = normalizeAvatarAnimalType(animalType);
  const cached = avatarTextureCache.get(safeAnimalType);
  if (cached) return cached;

  const promise = Asset.loadAsync(avatarTextureAssetModules[safeAnimalType]).then(
    ([asset]) => {
      const uri = asset.localUri ?? asset.uri;
      if (!uri) {
        throw new Error(`Missing ${safeAnimalType} avatar texture uri`);
      }
      const size = avatarTextureSize[safeAnimalType];
      const texture = new THREE.Texture({
        height: size.height,
        localUri: uri,
        uri,
        width: size.width,
      } as unknown as TexImageSource);
      texture.colorSpace = THREE.SRGBColorSpace;
      texture.flipY = false;
      texture.magFilter = THREE.LinearFilter;
      texture.minFilter = THREE.LinearMipmapLinearFilter;
      texture.needsUpdate = true;
      return texture;
    },
  );
  avatarTextureCache.set(safeAnimalType, promise);
  return promise;
}

function normalizeAvatarAnimalType(animalType: MeguriAnimalType): MeguriAnimalType {
  return animalType in avatarAssetModules ? animalType : "fox";
}

function cloneAvatarTemplate(template: THREE.Group): THREE.Group {
  const clone = (SkeletonUtils as SkeletonUtilsModule).clone;
  return (clone ? clone(template) : template.clone(true)) as THREE.Group;
}

function prepareAvatarClone(model: THREE.Group) {
  prepareAvatarMaterials(model);
  const box = new THREE.Box3().setFromObject(model);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const height = size.y || Math.max(size.x, size.z, 1);
  const scale = AVATAR_MODEL_TARGET_HEIGHT / Math.max(height, 0.001);
  model.scale.setScalar(scale);
  model.position.set(-center.x * scale, -box.min.y * scale, -center.z * scale);
}

function applyAvatarTexture(model: THREE.Group, texture: THREE.Texture) {
  model.traverse((object) => {
    if (!isMesh(object)) return;
    object.material = new THREE.MeshStandardMaterial({
      map: texture,
      metalness: 0,
      roughness: 0.78,
      side: THREE.DoubleSide,
      transparent: false,
    });
  });
}

function applyAvatarFallbackMaterial(model: THREE.Group) {
  model.traverse((object) => {
    if (!isMesh(object)) return;
    object.material = new THREE.MeshStandardMaterial({
      color: "#ffffff",
      metalness: 0,
      roughness: 0.82,
      side: THREE.DoubleSide,
    });
  });
}

function prepareAvatarMaterials(model: THREE.Object3D) {
  model.traverse((object) => {
    if (!isMesh(object)) return;
    object.frustumCulled = false;
    const materials = Array.isArray(object.material)
      ? object.material
      : [object.material];
    for (const material of materials) {
      const mapped = material as THREE.Material & {
        map?: THREE.Texture | null;
        vertexColors?: boolean;
      };
      if (object.geometry.getAttribute("color")) {
        mapped.vertexColors = true;
      }
      if (mapped.map) {
        mapped.map.colorSpace = THREE.SRGBColorSpace;
        mapped.map.needsUpdate = true;
      }
    }
  });
}

function isMesh(object: THREE.Object3D): object is THREE.Mesh {
  return (object as THREE.Mesh).isMesh === true;
}

function createSphere(
  position: [number, number, number],
  scale: [number, number, number],
  material: THREE.Material,
) {
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(1, 32, 24), material);
  mesh.position.set(...position);
  mesh.scale.set(...scale);
  return mesh;
}

function createArm(
  side: -1 | 1,
  furMaterial: THREE.Material,
  sleeveMaterial: THREE.Material,
) {
  const arm = new THREE.Group();
  arm.position.set(side * 0.29, 0.62, 0.05);
  arm.rotation.z = side * 0.34;
  arm.add(createSphere([side * 0.01, 0, 0.02], [0.078, 0.09, 0.07], sleeveMaterial));
  const forearm = new THREE.Mesh(
    new THREE.CylinderGeometry(0.064, 0.026, 0.54, 18),
    furMaterial,
  );
  forearm.position.set(side * 0.018, -0.28, 0.03);
  arm.add(forearm);
  arm.add(createSphere([side * 0.02, -0.57, 0.05], [0.05, 0.063, 0.045], furMaterial));
  return arm;
}

function createLeg(
  side: -1 | 1,
  furMaterial: THREE.Material,
  shoeMaterial: THREE.Material,
) {
  const leg = new THREE.Group();
  leg.position.set(side * 0.12, 0.24, 0.02);
  leg.rotation.z = side * 0.055;
  const shin = new THREE.Mesh(
    new THREE.CylinderGeometry(0.06, 0.048, 0.31, 18),
    furMaterial,
  );
  shin.position.set(side * 0.004, -0.105, 0.02);
  leg.add(shin);
  const foot = createSphere([side * 0.018, -0.225, 0.115], [0.095, 0.068, 0.13], shoeMaterial);
  foot.name = "foot";
  leg.add(foot);
  return leg;
}

function createTail(kind: MeguriAnimalType, furMaterial: THREE.Material) {
  const tail = new THREE.Group();
  tail.position.set(0, 0.48, -0.38);

  if (kind === "rabbit") {
    tail.add(createSphere([0, 0.02, 0], [0.14, 0.14, 0.13], furMaterial));
    return tail;
  }

  if (kind === "fox") {
    const tailStem = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.13, 0.72, 18), furMaterial);
    tailStem.position.set(0.2, 0.1, -0.07);
    tailStem.rotation.set(0.82, 0, -0.68);
    tail.add(tailStem);
    tail.add(createSphere([0.43, 0.34, -0.17], [0.14, 0.18, 0.12], furMaterial));
    return tail;
  }

  const tailStem = new THREE.Mesh(new THREE.CylinderGeometry(0.038, 0.07, 0.5, 16), furMaterial);
  tailStem.position.set(0.14, 0.08, -0.06);
  tailStem.rotation.set(0.75, 0, -0.62);
  tail.add(tailStem);
  tail.add(createSphere([0.31, 0.25, -0.14], [0.08, 0.1, 0.08], furMaterial));
  return tail;
}

function createClothes(
  clothMaterial: THREE.Material,
  clothLightMaterial: THREE.Material,
) {
  const group = new THREE.Group();
  group.add(createSphere([0, 0.47, 0.235], [0.21, 0.27, 0.035], clothMaterial));
  group.add(createSphere([0, 0.66, 0.26], [0.13, 0.055, 0.026], clothLightMaterial));
  const leftCollar = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.048, 0.026), clothLightMaterial);
  leftCollar.position.set(-0.065, 0.68, 0.285);
  leftCollar.rotation.z = -0.45;
  group.add(leftCollar);
  const rightCollar = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.048, 0.026), clothLightMaterial);
  rightCollar.position.set(0.065, 0.68, 0.285);
  rightCollar.rotation.z = 0.45;
  group.add(rightCollar);
  group.add(createClothDiamond([0, 0.49, 0.278], 0.105, clothLightMaterial));
  group.add(createClothDiamond([-0.07, 0.45, 0.279], 0.066, clothLightMaterial));
  group.add(createClothDiamond([0.07, 0.45, 0.279], 0.066, clothLightMaterial));
  group.add(createSphere([0, 0.36, 0.275], [0.16, 0.035, 0.025], clothLightMaterial));
  return group;
}

function createClothDiamond(
  position: [number, number, number],
  size: number,
  material: THREE.Material,
) {
  const diamond = new THREE.Mesh(new THREE.BoxGeometry(size, size, 0.02), material);
  diamond.position.set(...position);
  diamond.rotation.z = Math.PI / 4;
  return diamond;
}

function createTexturedFace(kind: MeguriAnimalType, accent: string) {
  const group = new THREE.Group();
  const state = createFaceTexture(kind, accent);
  const face = new THREE.Mesh(
    createCurvedFaceGeometry(),
    new THREE.MeshLambertMaterial({
      alphaTest: 0.02,
      map: state.texture,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
    }),
  );
  group.add(face);
  return { group, state };
}

function createCurvedFaceGeometry() {
  const columns = 24;
  const rows = 18;
  const width = 1.16;
  const height = 0.86;
  const centerY = 1.15;
  const centerZ = 0.02;
  const radiusX = 0.74;
  const radiusY = 0.65;
  const radiusZ = 0.54;
  const positions: number[] = [];
  const uvs: number[] = [];
  const indices: number[] = [];

  for (let row = 0; row <= rows; row += 1) {
    const v = row / rows;
    const y = centerY + (v - 0.5) * height;
    for (let column = 0; column <= columns; column += 1) {
      const u = column / columns;
      const x = (u - 0.5) * width;
      const nx = x / radiusX;
      const ny = (y - centerY) / radiusY;
      const surface = Math.sqrt(Math.max(0.001, 1 - nx * nx - ny * ny));
      const z = centerZ + surface * radiusZ + 0.038;
      positions.push(x, y, z);
      uvs.push(u, v);
    }
  }

  for (let row = 0; row < rows; row += 1) {
    for (let column = 0; column < columns; column += 1) {
      const a = row * (columns + 1) + column;
      const b = a + 1;
      const c = a + columns + 1;
      const d = c + 1;
      indices.push(a, c, b, b, c, d);
    }
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(positions, 3));
  geometry.setAttribute("uv", new THREE.Float32BufferAttribute(uvs, 2));
  geometry.setIndex(indices);
  geometry.computeVertexNormals();
  return geometry;
}

function createFaceTexture(kind: MeguriAnimalType, accent: string) {
  const width = 256;
  const height = 256;
  const data = new Uint8Array(width * height * 4);
  const face = hexToRgba(kind === "fox" ? "#fff0be" : "#fff4d8", 255);
  const ink = hexToRgba("#30263b", 255);
  const white = hexToRgba("#fffefa", 255);
  const cheek = hexToRgba("#f49aa7", 225);
  const nose = hexToRgba(kind === "rabbit" ? "#f47f98" : "#43324a", 255);
  const muzzle = hexToRgba("#fff9e7", 235);
  const accentRgba = hexToRgba(accent, 255);

  drawEllipse(data, width, height, 128, 130, kind === "rabbit" ? 110 : 120, 98, face);

  if (kind === "cat") {
    drawEllipse(data, width, height, 88, 84, 44, 38, face);
    drawEllipse(data, width, height, 168, 84, 44, 38, face);
    drawSoftLine(data, width, height, 128, 58, 110, 98, accentRgba, 6);
    drawSoftLine(data, width, height, 128, 58, 146, 98, accentRgba, 6);
  }
  if (kind === "rabbit") {
    drawEllipse(data, width, height, 80, 112, 42, 56, face);
    drawEllipse(data, width, height, 176, 112, 42, 56, face);
  }
  if (kind === "fox") {
    drawEllipse(data, width, height, 128, 158, 56, 34, muzzle);
  }

  drawEllipse(data, width, height, 70, 156, 18, 11, cheek);
  drawEllipse(data, width, height, 186, 156, 18, 11, cheek);
  drawEllipse(data, width, height, 128, 148, kind === "rabbit" ? 9 : 11, 8, nose);
  if (kind === "cat") {
    drawSoftLine(data, width, height, 102, 151, 62, 145, ink, 2.2);
    drawSoftLine(data, width, height, 103, 160, 64, 163, ink, 2.2);
    drawSoftLine(data, width, height, 154, 151, 194, 145, ink, 2.2);
    drawSoftLine(data, width, height, 153, 160, 192, 163, ink, 2.2);
  }

  const baseData = new Uint8Array(data);
  drawEyes(data, width, height, kind, false, accentRgba, ink, white);
  drawMouth(data, width, height, 0, ink);

  const texture = new THREE.DataTexture(data, width, height, THREE.RGBAFormat);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.flipY = true;
  texture.needsUpdate = true;
  return {
    baseData,
    data,
    height,
    kind,
    accent: accentRgba,
    ink,
    lastMouthFrame: -1,
    texture,
    white,
    width,
  };
}

function hexToRgba(hex: string, alpha: number) {
  const value = hex.replace("#", "");
  return [
    Number.parseInt(value.slice(0, 2), 16),
    Number.parseInt(value.slice(2, 4), 16),
    Number.parseInt(value.slice(4, 6), 16),
    alpha,
  ] as const;
}

function drawEllipse(
  data: Uint8Array,
  width: number,
  height: number,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  color: readonly [number, number, number, number],
) {
  const x0 = Math.max(0, Math.floor(cx - rx - 2));
  const x1 = Math.min(width - 1, Math.ceil(cx + rx + 2));
  const y0 = Math.max(0, Math.floor(cy - ry - 2));
  const y1 = Math.min(height - 1, Math.ceil(cy + ry + 2));

  for (let y = y0; y <= y1; y += 1) {
    for (let x = x0; x <= x1; x += 1) {
      const dx = (x - cx) / rx;
      const dy = (y - cy) / ry;
      const distance = dx * dx + dy * dy;
      if (distance > 1.08) continue;
      const softness = Math.min(1, Math.max(0, (1.08 - distance) / 0.12));
      blendPixel(data, width, x, y, color, softness);
    }
  }
}

function drawSmile(
  data: Uint8Array,
  width: number,
  height: number,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  color: readonly [number, number, number, number],
) {
  for (let i = 0; i <= 72; i += 1) {
    const t = (Math.PI * i) / 72;
    const x = cx - Math.cos(t) * rx;
    const y = cy + Math.sin(t) * ry;
    drawEllipse(data, width, height, x, y, 2.4, 2.4, color);
  }
}

function drawEyes(
  data: Uint8Array,
  width: number,
  height: number,
  kind: MeguriAnimalType,
  smiling: boolean,
  accent: readonly [number, number, number, number],
  ink: readonly [number, number, number, number],
  white: readonly [number, number, number, number],
) {
  if (smiling) {
    drawHappyEye(data, width, height, 88, 112, 25, 13, ink);
    drawHappyEye(data, width, height, 168, 112, 25, 13, ink);
    return;
  }

  const compactEyes = kind === "fox";
  const eyeRx = compactEyes ? 28 : 34;
  const eyeRy = compactEyes ? 34 : 50;
  const pupilRx = compactEyes ? 12 : 10;
  const pupilRy = compactEyes ? 23 : 36;
  drawEllipse(data, width, height, 88, 112, eyeRx, eyeRy, white);
  drawEllipse(data, width, height, 168, 112, eyeRx, eyeRy, white);
  drawEllipse(data, width, height, 88, 112, pupilRx, pupilRy, accent);
  drawEllipse(data, width, height, 168, 112, pupilRx, pupilRy, accent);
  drawEllipse(data, width, height, 88, 112, Math.max(4, pupilRx - 4), Math.max(16, pupilRy - 5), ink);
  drawEllipse(data, width, height, 168, 112, Math.max(4, pupilRx - 4), Math.max(16, pupilRy - 5), ink);
  drawEllipse(data, width, height, 80, 95, 6, 8, white);
  drawEllipse(data, width, height, 160, 95, 6, 8, white);
}

function drawHappyEye(
  data: Uint8Array,
  width: number,
  height: number,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  color: readonly [number, number, number, number],
) {
  for (let i = 0; i <= 42; i += 1) {
    const t = (Math.PI * i) / 42;
    const x = cx - Math.cos(t) * rx;
    const y = cy - Math.sin(t) * ry;
    drawEllipse(data, width, height, x, y, 3.1, 3.1, color);
  }
}

function drawMouth(
  data: Uint8Array,
  width: number,
  height: number,
  openness: number,
  ink: readonly [number, number, number, number],
) {
  if (openness <= 0.08) {
    drawSmile(data, width, height, 128, 164, 38, 14, ink);
    return;
  }

  const mouthWidth = 13 + openness * 12;
  const mouthHeight = 4 + openness * 15;
  drawEllipse(data, width, height, 128, 166, mouthWidth, mouthHeight, ink);
  drawEllipse(
    data,
    width,
    height,
    128,
    159,
    mouthWidth * 0.45,
    Math.max(2, mouthHeight * 0.18),
    [255, 255, 255, 54],
  );
}

function drawSoftLine(
  data: Uint8Array,
  width: number,
  height: number,
  x0: number,
  y0: number,
  x1: number,
  y1: number,
  color: readonly [number, number, number, number],
  thickness: number,
) {
  const steps = Math.ceil(Math.hypot(x1 - x0, y1 - y0));
  for (let i = 0; i <= steps; i += 1) {
    const rate = steps === 0 ? 0 : i / steps;
    const x = x0 + (x1 - x0) * rate;
    const y = y0 + (y1 - y0) * rate;
    drawEllipse(data, width, height, x, y, thickness, thickness, color);
  }
}

function blendPixel(
  data: Uint8Array,
  width: number,
  x: number,
  y: number,
  color: readonly [number, number, number, number],
  amount: number,
) {
  const index = (y * width + x) * 4;
  const sourceAlpha = (color[3] / 255) * amount;
  const destAlpha = data[index + 3] / 255;
  const outAlpha = sourceAlpha + destAlpha * (1 - sourceAlpha);
  if (outAlpha <= 0) return;
  data[index] = Math.round((color[0] * sourceAlpha + data[index] * destAlpha * (1 - sourceAlpha)) / outAlpha);
  data[index + 1] = Math.round((color[1] * sourceAlpha + data[index + 1] * destAlpha * (1 - sourceAlpha)) / outAlpha);
  data[index + 2] = Math.round((color[2] * sourceAlpha + data[index + 2] * destAlpha * (1 - sourceAlpha)) / outAlpha);
  data[index + 3] = Math.round(outAlpha * 255);
}

function createAnimalEars(kind: MeguriAnimalType, furMaterial: THREE.Material) {
  const group = new THREE.Group();
  const innerMaterial = new THREE.MeshLambertMaterial({
    color: "#fff0bd",
  });

  if (kind === "rabbit") {
    const left = createSphere([-0.27, 1.88, -0.03], [0.12, 0.44, 0.08], furMaterial);
    left.rotation.set(0.05, 0.05, -0.2);
    group.add(left);
    const right = createSphere([0.27, 1.88, -0.03], [0.12, 0.44, 0.08], furMaterial);
    right.rotation.set(0.05, -0.05, 0.2);
    group.add(right);
    const innerLeft = createSphere([-0.27, 1.88, 0.06], [0.05, 0.27, 0.03], innerMaterial);
    innerLeft.rotation.set(0.05, 0.05, -0.2);
    group.add(innerLeft);
    const innerRight = createSphere([0.27, 1.88, 0.06], [0.05, 0.27, 0.03], innerMaterial);
    innerRight.rotation.set(0.05, -0.05, 0.2);
    group.add(innerRight);
    return group;
  }

  const left = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 3), furMaterial);
  left.position.set(-0.42, 1.78, 0.02);
  left.rotation.set(0, 0, 0.18);
  left.scale.set(0.22, 0.58, 0.12);
  group.add(left);
  const right = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 3), furMaterial);
  right.position.set(0.42, 1.78, 0.02);
  right.rotation.set(0, 0, -0.18);
  right.scale.set(0.22, 0.58, 0.12);
  group.add(right);
  const innerLeft = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 3), innerMaterial);
  innerLeft.position.set(-0.42, 1.78, 0.1);
  innerLeft.rotation.set(0, 0, 0.18);
  innerLeft.scale.set(0.1, 0.31, 0.04);
  group.add(innerLeft);
  const innerRight = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 3), innerMaterial);
  innerRight.position.set(0.42, 1.78, 0.1);
  innerRight.rotation.set(0, 0, -0.18);
  innerRight.scale.set(0.1, 0.31, 0.04);
  group.add(innerRight);
  return group;
}

function createTufts(material: THREE.Material) {
  const group = new THREE.Group();
  const center = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 8), material);
  center.position.set(0, 1.78, 0.12);
  center.rotation.set(0.12, 0, 0);
  center.scale.set(0.045, 0.11, 0.045);
  group.add(center);

  const left = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 8), material);
  left.position.set(-0.12, 1.72, 0.12);
  left.rotation.set(0.05, 0, -0.42);
  left.scale.set(0.04, 0.09, 0.04);
  group.add(left);

  const right = new THREE.Mesh(new THREE.ConeGeometry(1, 1, 8), material);
  right.position.set(0.12, 1.72, 0.12);
  right.rotation.set(0.05, 0, 0.42);
  right.scale.set(0.04, 0.09, 0.04);
  group.add(right);
  return group;
}

function disposeRuntime(runtime: ThreeRuntime | null) {
  if (!runtime) return;
  runtime.disposed = true;
  if (runtime.frameId !== null) cancelAnimationFrame(runtime.frameId);
  runtime.scene.traverse((object) => {
    const mesh = object as THREE.Mesh;
    if (mesh.geometry) mesh.geometry.dispose();
    const material = mesh.material;
    if (Array.isArray(material)) {
      material.forEach(disposeMaterial);
    } else if (material) {
      disposeMaterial(material);
    }
  });
  runtime.renderer.dispose();
}

function disposeMaterial(material: THREE.Material) {
  const mapped = material as THREE.Material & { map?: THREE.Texture | null };
  mapped.map?.dispose();
  material.dispose();
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    overflow: "hidden",
  },
  glView: {
    flex: 1,
  },
  depthLabel: {
    backgroundColor: "rgba(255,255,255,0.7)",
    borderRadius: 999,
    left: 18,
    paddingHorizontal: 10,
    paddingVertical: 5,
    position: "absolute",
    top: 16,
  },
  depthLabelText: {
    color: "rgba(58,50,74,0.5)",
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 1.2,
  },
  failed: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  failedTitle: {
    color: ihubColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  failedText: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 4,
  },
});
