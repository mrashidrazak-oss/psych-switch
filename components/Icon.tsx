// Lightweight SVG icon library — hand-curated set used across the app.
// Stroke-only design (Lucide-style) for clinical clarity at any size.
//
// Usage:  <Icon name="syringe" size={20} color="#3b82f6" />
import Svg, { Circle, Path, Rect, Line, Polyline } from 'react-native-svg';

export type IconName =
  | 'arrow-right'
  | 'arrow-left'
  | 'pill'
  | 'syringe'
  | 'beaker'
  | 'clipboard-check'
  | 'shield'
  | 'sparkles'
  | 'info'
  | 'plus'
  | 'check'
  | 'chevron-right'
  | 'chevron-left'
  | 'share'
  | 'refresh'
  | 'home'
  | 'document'
  | 'activity'
  | 'search'
  | 'settings'
  | 'calendar'
  | 'star'
  | 'trash'
  | 'user'
  | 'heart-pulse'
  | 'flask';

export function Icon({
  name,
  size = 20,
  color = 'currentColor',
  strokeWidth = 1.75,
}: {
  name: IconName;
  size?: number;
  color?: string;
  strokeWidth?: number;
}) {
  const props = {
    width: size,
    height: size,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: color,
    strokeWidth,
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
  };

  switch (name) {
    case 'arrow-right':
      return (
        <Svg {...props}>
          <Line x1="5" y1="12" x2="19" y2="12" />
          <Polyline points="12 5 19 12 12 19" />
        </Svg>
      );
    case 'arrow-left':
      return (
        <Svg {...props}>
          <Line x1="19" y1="12" x2="5" y2="12" />
          <Polyline points="12 19 5 12 12 5" />
        </Svg>
      );
    case 'pill':
      return (
        <Svg {...props}>
          <Path d="m10.5 20.5 10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7Z" />
          <Path d="m8.5 8.5 7 7" />
        </Svg>
      );
    case 'syringe':
      return (
        <Svg {...props}>
          <Path d="m18 2 4 4" />
          <Path d="m17 7 3-3" />
          <Path d="M19 9 8.7 19.3c-1 1-2.5 1-3.4 0l-.6-.6c-1-1-1-2.5 0-3.4L15 5" />
          <Path d="m9 11 4 4" />
          <Path d="m5 19-3 3" />
          <Path d="m14 4 6 6" />
        </Svg>
      );
    case 'beaker':
      return (
        <Svg {...props}>
          <Path d="M4.5 3h15" />
          <Path d="M6 3v16a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V3" />
          <Path d="M6 14h12" />
        </Svg>
      );
    case 'clipboard-check':
      return (
        <Svg {...props}>
          <Rect width="8" height="4" x="8" y="2" rx="1" ry="1" />
          <Path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
          <Path d="m9 14 2 2 4-4" />
        </Svg>
      );
    case 'shield':
      return (
        <Svg {...props}>
          <Path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1Z" />
        </Svg>
      );
    case 'sparkles':
      return (
        <Svg {...props}>
          <Path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z" />
          <Path d="M20 3v4" />
          <Path d="M22 5h-4" />
        </Svg>
      );
    case 'info':
      return (
        <Svg {...props}>
          <Circle cx="12" cy="12" r="10" />
          <Path d="M12 16v-4" />
          <Path d="M12 8h.01" />
        </Svg>
      );
    case 'plus':
      return (
        <Svg {...props}>
          <Path d="M5 12h14" />
          <Path d="M12 5v14" />
        </Svg>
      );
    case 'check':
      return (
        <Svg {...props}>
          <Polyline points="20 6 9 17 4 12" />
        </Svg>
      );
    case 'chevron-right':
      return (
        <Svg {...props}>
          <Polyline points="9 18 15 12 9 6" />
        </Svg>
      );
    case 'chevron-left':
      return (
        <Svg {...props}>
          <Polyline points="15 18 9 12 15 6" />
        </Svg>
      );
    case 'share':
      return (
        <Svg {...props}>
          <Path d="M12 2v13" />
          <Path d="m16 6-4-4-4 4" />
          <Path d="M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-7" />
        </Svg>
      );
    case 'refresh':
      return (
        <Svg {...props}>
          <Path d="M3 12a9 9 0 0 1 15.5-6.36L21 8" />
          <Path d="M21 3v5h-5" />
          <Path d="M21 12a9 9 0 0 1-15.5 6.36L3 16" />
          <Path d="M3 21v-5h5" />
        </Svg>
      );
    case 'home':
      return (
        <Svg {...props}>
          <Path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8" />
          <Path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
        </Svg>
      );
    case 'document':
      return (
        <Svg {...props}>
          <Path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z" />
          <Polyline points="14 2 14 8 20 8" />
          <Line x1="16" y1="13" x2="8" y2="13" />
          <Line x1="16" y1="17" x2="8" y2="17" />
          <Line x1="10" y1="9" x2="8" y2="9" />
        </Svg>
      );
    case 'activity':
      return (
        <Svg {...props}>
          <Polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
        </Svg>
      );
    case 'search':
      return (
        <Svg {...props}>
          <Circle cx="11" cy="11" r="8" />
          <Line x1="21" y1="21" x2="16.65" y2="16.65" />
        </Svg>
      );
    case 'settings':
      return (
        <Svg {...props}>
          <Path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
          <Circle cx="12" cy="12" r="3" />
        </Svg>
      );
    case 'calendar':
      return (
        <Svg {...props}>
          <Rect width="18" height="18" x="3" y="4" rx="2" ry="2" />
          <Line x1="16" y1="2" x2="16" y2="6" />
          <Line x1="8" y1="2" x2="8" y2="6" />
          <Line x1="3" y1="10" x2="21" y2="10" />
        </Svg>
      );
    case 'star':
      return (
        <Svg {...props}>
          <Path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
        </Svg>
      );
    case 'trash':
      return (
        <Svg {...props}>
          <Polyline points="3 6 5 6 21 6" />
          <Path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
          <Path d="M10 11v6" />
          <Path d="M14 11v6" />
          <Path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" />
        </Svg>
      );
    case 'user':
      return (
        <Svg {...props}>
          <Path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <Circle cx="12" cy="7" r="4" />
        </Svg>
      );
    case 'heart-pulse':
      return (
        <Svg {...props}>
          <Path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7Z" />
          <Path d="M3.22 12H9.5l.5-1 2 4.5 2-7 1.5 3.5h5.27" />
        </Svg>
      );
    case 'flask':
      return (
        <Svg {...props}>
          <Path d="M9 2v6.5L3 21h18L15 8.5V2" />
          <Path d="M9 2h6" />
          <Path d="M5.5 16h13" />
        </Svg>
      );
  }
}
