// ハコニワ3Dルームの生成（手続き的に組み立てる）
// 子どものテーマカラーから部屋の配色を導出し、思い出の数に応じて家具が増える
// （サービス概要書の「ハコニワ空間の生成」「空間の拡張機能」に対応）
import * as THREE from 'three';

export const FLOOR_HALF = 1.7; // 床の半径（正規化座標 -1..1 をこの範囲へ写像）

export interface RoomTheme {
  wall: THREE.Color;
  wallShade: THREE.Color;
  floor: THREE.Color;
  rug: THREE.Color;
  accent: THREE.Color;
  bg: THREE.Color;
}

export function themeFromTone(tone: string): RoomTheme {
  const accent = new THREE.Color(tone);
  const wall = accent.clone().lerp(new THREE.Color('#FFF6E8'), 0.82);
  const wallShade = wall.clone().multiplyScalar(0.92);
  const rug = accent.clone().lerp(new THREE.Color('#FFFFFF'), 0.35);
  return {
    wall,
    wallShade,
    floor: new THREE.Color('#D8A96E'),
    rug,
    accent,
    bg: new THREE.Color('#F6EDDD'),
  };
}

function mat(color: THREE.Color | string): THREE.MeshLambertMaterial {
  return new THREE.MeshLambertMaterial({ color: color instanceof THREE.Color ? color : new THREE.Color(color) });
}

function box(
  w: number, h: number, d: number,
  color: THREE.Color | string,
  x: number, y: number, z: number,
): THREE.Mesh {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat(color));
  m.position.set(x, y, z);
  return m;
}

/**
 * 部屋を組み立てて scene に追加し、床メッシュ（配置レイキャスト用）を返す。
 * propLevel: 0=基本 / 1=たな追加 / 2=植木追加 / 3=かざり棚追加（空間の拡張）
 */
export function buildRoom(scene: THREE.Scene, theme: RoomTheme, propLevel: number): THREE.Mesh {
  scene.background = theme.bg;

  // ライト（やわらかい暖色）
  const ambient = new THREE.AmbientLight('#FFF3E2', 0.95);
  scene.add(ambient);
  const sun = new THREE.DirectionalLight('#FFFFFF', 1.25);
  sun.position.set(3.5, 6, 2.5);
  scene.add(sun);

  const H = FLOOR_HALF;

  // 床（木の台座つき）
  const base = box(H * 2 + 0.3, 0.22, H * 2 + 0.3, '#B0824E', 0, -0.17, 0);
  scene.add(base);
  const floor = box(H * 2, 0.12, H * 2, theme.floor, 0, -0.06, 0);
  floor.name = 'floor';
  scene.add(floor);

  // 壁（奥と左のコーナー）
  const wallH = 1.9;
  const backWall = box(H * 2, wallH, 0.12, theme.wall, 0, wallH / 2, -H - 0.06);
  scene.add(backWall);
  const leftWall = box(0.12, wallH, H * 2, theme.wallShade, -H - 0.06, wallH / 2, 0);
  scene.add(leftWall);
  // 幅木
  scene.add(box(H * 2, 0.14, 0.05, '#FFFFFF', 0, 0.07, -H + 0.03));
  scene.add(box(0.05, 0.14, H * 2, '#FFFFFF', -H + 0.03, 0.07, 0));

  // 窓（奥の壁・あかり）
  const win = box(0.9, 0.75, 0.05, '#FFF6D9', 0.45, 1.1, -H + 0.02);
  scene.add(win);
  scene.add(box(1.0, 0.85, 0.03, '#FFFFFF', 0.45, 1.1, -H + 0.005));
  scene.add(box(0.04, 0.75, 0.06, '#FFFFFF', 0.45, 1.1, -H + 0.03));
  scene.add(box(0.9, 0.04, 0.06, '#FFFFFF', 0.45, 1.1, -H + 0.03));

  // ラグ（まるい）
  const rug = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.62, 0.03, 28), mat(theme.rug));
  rug.position.set(0.35, 0.015, 0.45);
  scene.add(rug);

  // ベッド（左の壁ぎわ）
  const bed = new THREE.Group();
  bed.add(box(0.8, 0.22, 1.3, '#B0824E', 0, 0.11, 0));
  bed.add(box(0.74, 0.14, 1.24, theme.accent.clone().lerp(new THREE.Color('#FFFFFF'), 0.55), 0, 0.3, 0));
  bed.add(box(0.6, 0.1, 0.3, '#FFFFFF', 0, 0.4, -0.42));
  bed.add(box(0.8, 0.34, 0.06, '#9A7040', 0, 0.28, -0.68));
  bed.position.set(-H + 0.55, 0, -H + 0.8);
  scene.add(bed);

  // サイドテーブル + ランプ
  const table = new THREE.Group();
  table.add(box(0.34, 0.3, 0.34, '#B98B57', 0, 0.15, 0));
  const lampPole = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 0.22, 8), mat('#8A6238'));
  lampPole.position.set(0, 0.41, 0);
  table.add(lampPole);
  const lampShade = new THREE.Mesh(new THREE.ConeGeometry(0.11, 0.14, 12), mat('#FFE9B8'));
  lampShade.position.set(0, 0.55, 0);
  table.add(lampShade);
  table.position.set(-H + 0.35, 0, 0.55);
  scene.add(table);

  // --- 空間の拡張（思い出が増えると家具が増える） ---
  if (propLevel >= 1) {
    // たな
    const shelf = new THREE.Group();
    shelf.add(box(0.9, 1.0, 0.26, '#B98B57', 0, 0.5, 0));
    shelf.add(box(0.82, 0.05, 0.2, '#8A6238', 0, 0.35, 0.02));
    shelf.add(box(0.82, 0.05, 0.2, '#8A6238', 0, 0.68, 0.02));
    shelf.add(box(0.16, 0.2, 0.14, theme.accent, -0.22, 0.47, 0.03));
    shelf.add(box(0.14, 0.16, 0.12, '#7FA6C4', 0.2, 0.79, 0.03));
    shelf.position.set(0.95, 0, -H + 0.2);
    scene.add(shelf);
  }
  if (propLevel >= 2) {
    // 植木
    const plant = new THREE.Group();
    const pot = new THREE.Mesh(new THREE.CylinderGeometry(0.13, 0.1, 0.2, 10), mat('#C97B4A'));
    pot.position.set(0, 0.1, 0);
    plant.add(pot);
    const leaves = new THREE.Mesh(new THREE.SphereGeometry(0.2, 10, 8), mat('#7E9E62'));
    leaves.position.set(0, 0.36, 0);
    plant.add(leaves);
    plant.position.set(H - 0.3, 0, -H + 0.35);
    scene.add(plant);
  }
  if (propLevel >= 3) {
    // かべのかざり（絵）
    scene.add(box(0.4, 0.32, 0.04, '#FFFFFF', -0.7, 1.25, -H + 0.02));
    scene.add(box(0.32, 0.24, 0.04, theme.rug, -0.7, 1.25, -H + 0.035));
    scene.add(box(0.3, 0.4, 0.04, '#FFFFFF', -H + 0.02, 1.2, -0.6));
    scene.add(box(0.22, 0.32, 0.04, '#C9DAE8', -H + 0.035, 1.2, -0.6));
  }

  return floor;
}

/** モノのピン（白い玉＋色つきの頭、地面に立つ） */
export function makePin(tone: string): THREE.Group {
  const g = new THREE.Group();
  const stick = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, 0.3, 8), mat('#FFFFFF'));
  stick.position.y = 0.15;
  g.add(stick);
  const head = new THREE.Mesh(
    new THREE.SphereGeometry(0.11, 16, 12),
    new THREE.MeshLambertMaterial({ color: new THREE.Color(tone) }),
  );
  head.position.y = 0.36;
  g.add(head);
  const dot = new THREE.Mesh(new THREE.SphereGeometry(0.045, 10, 8), mat('#FFFFFF'));
  dot.position.set(0, 0.36, 0.085);
  g.add(dot);
  return g;
}
