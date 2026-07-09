// リアルタイム3Dハコニワルーム（expo-gl + three.js）
// - ドラッグで回転（オービット）
// - ピンをタップで選択 / 配置モードでは床タップで配置
// - 思い出の数に応じて部屋が拡張される
import React, {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import { PanResponder, StyleProp, View, ViewStyle } from 'react-native';
import { GLView, ExpoWebGLRenderingContext } from 'expo-gl';
import * as THREE from 'three';
import { buildRoom, makePin, themeFromTone, FLOOR_HALF } from './roomBuilder';
import type { RoomPos } from '../store/types';

export interface RoomItem {
  id: string;
  tone: string;
  pos: RoomPos;
}

export interface Room3DHandle {
  resetCamera: () => void;
}

interface Props {
  items: RoomItem[];
  selectedId: string | null;
  childTone: string;
  placeMode: boolean;
  popItemId?: string | null; // 追加直後のポップ演出対象
  onSelect: (id: string) => void;
  onPlace: (pos: RoomPos) => void;
  style?: StyleProp<ViewStyle>;
}

const DEFAULT_THETA = Math.PI / 4; // 部屋のコーナー（奥・左の壁）が背景になる向き
const DEFAULT_PHI = 0.62;
const RADIUS = 5.4;

const Room3D = forwardRef<Room3DHandle, Props>(function Room3D(
  { items, selectedId, childTone, placeMode, popItemId, onSelect, onPlace, style },
  ref,
) {
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);
  const floorRef = useRef<THREE.Mesh | null>(null);
  const pinGroupRef = useRef<THREE.Group | null>(null);
  const pinsRef = useRef<Map<string, THREE.Group>>(new Map());
  const rafRef = useRef<number>(0);
  const sizeRef = useRef({ w: 1, h: 1 });
  const theta = useRef(DEFAULT_THETA);
  const phi = useRef(DEFAULT_PHI);
  const itemsRef = useRef(items);
  const selectedRef = useRef(selectedId);
  const placeModeRef = useRef(placeMode);
  const popRef = useRef<{ id: string; start: number } | null>(null);
  const propLevelRef = useRef(propLevel(items.length));

  itemsRef.current = items;
  selectedRef.current = selectedId;
  placeModeRef.current = placeMode;

  useImperativeHandle(ref, () => ({
    resetCamera: () => {
      theta.current = DEFAULT_THETA;
      phi.current = DEFAULT_PHI;
    },
  }));

  function propLevel(count: number): number {
    if (count >= 12) return 3;
    if (count >= 8) return 2;
    if (count >= 5) return 1;
    return 0;
  }

  // ピンをシーンに同期
  const syncPins = useCallback(() => {
    const group = pinGroupRef.current;
    if (!group) return;
    const map = pinsRef.current;
    const alive = new Set<string>();
    for (const it of itemsRef.current) {
      alive.add(it.id);
      let pin = map.get(it.id);
      if (!pin) {
        pin = makePin(it.tone);
        pin.userData.itemId = it.id;
        map.set(it.id, pin);
        group.add(pin);
        if (popItemIdRefCheck(it.id)) {
          popRef.current = { id: it.id, start: Date.now() };
        }
      }
      pin.position.set(it.pos.x * (FLOOR_HALF - 0.25), 0, it.pos.z * (FLOOR_HALF - 0.25));
      pin.userData.phase = pin.userData.phase ?? Math.random() * Math.PI * 2;
    }
    for (const [id, pin] of map) {
      if (!alive.has(id)) {
        group.remove(pin);
        map.delete(id);
      }
    }
  }, []);

  const popItemIdRefCurrent = useRef<string | null | undefined>(popItemId);
  popItemIdRefCurrent.current = popItemId;
  function popItemIdRefCheck(id: string) {
    return popItemIdRefCurrent.current === id;
  }

  useEffect(() => {
    syncPins();
  }, [items, syncPins]);

  const onContextCreate = useCallback((gl: ExpoWebGLRenderingContext) => {
    const width = gl.drawingBufferWidth;
    const height = gl.drawingBufferHeight;

    // expo-gl のコンテキストで three の WebGLRenderer を作る（canvas シム）
    const glAny = gl as unknown as { canvas?: unknown };
    const canvas =
      glAny.canvas ??
      ({
        width,
        height,
        clientWidth: width,
        clientHeight: height,
        style: {},
        addEventListener: () => {},
        removeEventListener: () => {},
        getContext: () => gl,
      } as unknown);
    const renderer = new THREE.WebGLRenderer({
      context: gl as unknown as WebGL2RenderingContext,
      canvas: canvas as HTMLCanvasElement,
      antialias: true,
    });
    renderer.setSize(width, height, false);
    renderer.setPixelRatio(1);

    const scene = new THREE.Scene();
    sceneRef.current = scene;

    const camera = new THREE.PerspectiveCamera(42, width / height, 0.1, 100);
    cameraRef.current = camera;

    const theme = themeFromTone(childToneRef.current);
    floorRef.current = buildRoom(scene, theme, propLevelRef.current);

    const pinGroup = new THREE.Group();
    pinGroupRef.current = pinGroup;
    scene.add(pinGroup);
    syncPins();

    const target = new THREE.Vector3(0, 0.55, 0);

    const loop = () => {
      rafRef.current = requestAnimationFrame(loop);
      const t = Date.now() / 1000;

      camera.position.set(
        target.x + RADIUS * Math.cos(phi.current) * Math.sin(theta.current),
        target.y + RADIUS * Math.sin(phi.current),
        target.z + RADIUS * Math.cos(phi.current) * Math.cos(theta.current),
      );
      camera.lookAt(target);

      // ピンのふわふわ・選択強調・追加ポップ
      for (const [id, pin] of pinsRef.current) {
        const phase = (pin.userData.phase as number) ?? 0;
        pin.position.y = 0.03 + Math.sin(t * 2 + phase) * 0.03;
        let s = selectedRef.current === id ? 1.35 : 1;
        const pop = popRef.current;
        if (pop && pop.id === id) {
          const e = (Date.now() - pop.start) / 500;
          if (e < 1) {
            s *= e < 0.6 ? (e / 0.6) * 1.15 : 1.15 - 0.15 * ((e - 0.6) / 0.4);
          } else {
            popRef.current = null;
          }
        }
        pin.scale.setScalar(s);
      }

      renderer.render(scene, camera);
      gl.endFrameEXP?.();
    };
    loop();
  }, [syncPins]);

  const childToneRef = useRef(childTone);
  childToneRef.current = childTone;

  useEffect(() => () => cancelAnimationFrame(rafRef.current), []);

  // タップ位置からレイキャスト
  const handleTap = useCallback(
    (px: number, py: number) => {
      const camera = cameraRef.current;
      if (!camera) return;
      const { w, h } = sizeRef.current;
      const ndc = new THREE.Vector2((px / w) * 2 - 1, -(py / h) * 2 + 1);
      const ray = new THREE.Raycaster();
      ray.setFromCamera(ndc, camera);

      if (placeModeRef.current && floorRef.current) {
        const hit = ray.intersectObject(floorRef.current, false)[0];
        if (hit) {
          const nx = Math.max(-0.95, Math.min(0.95, hit.point.x / (FLOOR_HALF - 0.25)));
          const nz = Math.max(-0.95, Math.min(0.95, hit.point.z / (FLOOR_HALF - 0.25)));
          onPlace({ x: nx, z: nz });
        }
        return;
      }

      const pins = pinGroupRef.current;
      if (!pins) return;
      const hits = ray.intersectObjects(pins.children, true);
      if (hits.length > 0) {
        let obj: THREE.Object3D | null = hits[0].object;
        while (obj && !obj.userData.itemId) obj = obj.parent;
        if (obj?.userData.itemId) onSelect(obj.userData.itemId as string);
      }
    },
    [onPlace, onSelect],
  );

  const gesture = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (e) => {
          gestureState.current = {
            moved: 0,
            start: Date.now(),
            x: e.nativeEvent.locationX,
            y: e.nativeEvent.locationY,
          };
        },
        onPanResponderMove: (_e, g) => {
          const st = gestureState.current;
          st.moved = Math.max(st.moved, Math.abs(g.dx) + Math.abs(g.dy));
          theta.current -= g.vx * 0.045;
          phi.current = Math.max(0.28, Math.min(1.15, phi.current + g.vy * 0.03));
        },
        onPanResponderRelease: () => {
          const st = gestureState.current;
          if (st.moved < 8 && Date.now() - st.start < 350) {
            handleTap(st.x, st.y);
          }
        },
      }),
    [handleTap],
  );
  const gestureState = useRef({ moved: 0, start: 0, x: 0, y: 0 });

  return (
    <View
      style={style}
      onLayout={(e) => {
        sizeRef.current = { w: e.nativeEvent.layout.width, h: e.nativeEvent.layout.height };
      }}
      {...gesture.panHandlers}
    >
      <GLView style={{ flex: 1 }} onContextCreate={onContextCreate} />
    </View>
  );
});

export default Room3D;
