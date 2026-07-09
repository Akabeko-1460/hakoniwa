// プロトタイプのインラインSVGを忠実に移植したアイコン群
import React from 'react';
import Svg, { Circle, Path, Rect } from 'react-native-svg';

export function HomeIcon({ size = 23, color = '#B7A488', filled = false }: { size?: number; color?: string; filled?: boolean }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M4 11l8-6 8 6v8a1 1 0 01-1 1h-4v-6h-6v6H5a1 1 0 01-1-1z"
        fill={filled ? color : 'none'}
        stroke={filled ? undefined : color}
        strokeWidth={filled ? 0 : 2}
        strokeLinejoin="round"
      />
    </Svg>
  );
}

export function SearchIcon({ size = 23, color = '#B7A488' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx={11} cy={11} r={6} stroke={color} strokeWidth={2} />
      <Path d="M15.5 15.5L20 20" stroke={color} strokeWidth={2} strokeLinecap="round" />
    </Svg>
  );
}

export function PlusIcon({ size = 20, color = '#fff', strokeWidth = 2.4 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 20 20">
      <Path d="M10 3v14M3 10h14" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
    </Svg>
  );
}

export function HeartIcon({ size = 23, color = '#B7A488', filled = false }: { size?: number; color?: string; filled?: boolean }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 20s-7-4.5-7-9.5A3.5 3.5 0 0112 7a3.5 3.5 0 017 3.5C19 15.5 12 20 12 20z"
        stroke={color}
        strokeWidth={2}
        strokeLinejoin="round"
        fill={filled ? '#FBEDE4' : 'none'}
      />
    </Svg>
  );
}

export function GearIcon({ size = 23, color = '#B7A488' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx={12} cy={12} r={3.2} stroke={color} strokeWidth={2} />
      <Path
        d="M12 4v2M12 18v2M4 12h2M18 12h2M6 6l1.5 1.5M16.5 16.5L18 18M18 6l-1.5 1.5M7.5 16.5L6 18"
        stroke={color}
        strokeWidth={2}
        strokeLinecap="round"
      />
    </Svg>
  );
}

export function BackIcon({ size = 17, color = '#7A6650' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 20 20">
      <Path d="M13 4l-6 6 6 6" stroke={color} strokeWidth={2.2} fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

export function ChevronRightIcon({ size = 16, color = '#C6B79E' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 20 20">
      <Path d="M7 4l6 6-6 6" stroke={color} strokeWidth={2.2} fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

export function CheckIcon({ size = 21, color = '#8BA36F', strokeWidth = 2.6 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M5 12l5 5L20 6" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

export function ReloadIcon({ size = 20, color = '#7A6650', strokeWidth = 2.2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M4 12a8 8 0 108-8" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      <Path d="M4 5v4h4" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

export function ShareIcon({ size = 17, color = '#7A6650' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx={6} cy={12} r={2.2} fill={color} />
      <Circle cx={18} cy={6} r={2.2} fill={color} />
      <Circle cx={18} cy={18} r={2.2} fill={color} />
      <Path d="M8 11l8-4M8 13l8 4" stroke={color} strokeWidth={1.6} />
    </Svg>
  );
}

export function MicIcon({ size = 16, color = '#fff' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Rect x={9} y={3} width={6} height={12} rx={3} fill={color} />
      <Path d="M6 11a6 6 0 0012 0M12 17v3" stroke={color} strokeWidth={2} strokeLinecap="round" />
    </Svg>
  );
}

export function PlayIcon({ size = 9, color = '#fff' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 10 12">
      <Path d="M0 0l10 6-10 6z" fill={color} />
    </Svg>
  );
}

export function CloseIcon({ size = 12, color = '#9A8368' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 14 14">
      <Path d="M2 2l10 10M12 2L2 12" stroke={color} strokeWidth={2} strokeLinecap="round" />
    </Svg>
  );
}

// こえメモの波形（memory 画面）
export function WaveformSvg() {
  const groupA = [
    [0, 9, 8], [7, 5, 16], [14, 2, 22], [21, 7, 12], [28, 4, 18],
    [35, 10, 6], [42, 6, 14], [49, 3, 20], [56, 8, 10], [63, 5, 16],
  ];
  const groupB = [
    [70, 7, 12], [77, 4, 18], [84, 9, 8], [91, 6, 14], [98, 2, 22],
    [105, 8, 10], [112, 5, 16], [119, 10, 6], [126, 6, 14], [133, 4, 18], [140, 9, 8],
  ];
  return (
    <Svg width="100%" height={26} viewBox="0 0 150 26" preserveAspectRatio="none">
      {groupA.map(([x, y, h]) => (
        <Rect key={`a${x}`} x={x} y={y} width={3} height={h} rx={1.5} fill="#E7C4AE" />
      ))}
      {groupB.map(([x, y, h]) => (
        <Rect key={`b${x}`} x={x} y={y} width={3} height={h} rx={1.5} fill="#EBDCC6" />
      ))}
    </Svg>
  );
}
