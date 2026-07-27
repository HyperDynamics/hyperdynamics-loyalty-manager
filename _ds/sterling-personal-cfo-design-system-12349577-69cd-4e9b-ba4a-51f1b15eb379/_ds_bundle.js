/* @ds-bundle: {"format":3,"namespace":"SterlingPersonalCFODesignSystem_123495","components":[{"name":"Avatar","sourcePath":"components/core/Avatar.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Input","sourcePath":"components/core/Input.jsx"},{"name":"ListRow","sourcePath":"components/core/ListRow.jsx"},{"name":"ProgressRing","sourcePath":"components/core/ProgressRing.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"StatTile","sourcePath":"components/core/StatTile.jsx"},{"name":"Toggle","sourcePath":"components/core/Toggle.jsx"},{"name":"Coin","sourcePath":"components/finance/Coin.jsx"},{"name":"CreditCard3D","sourcePath":"components/finance/CreditCard3D.jsx"}],"sourceHashes":{"components/core/Avatar.jsx":"8b3aecc037cf","components/core/Badge.jsx":"ee2b8eff31c2","components/core/Button.jsx":"e71d897bc4d4","components/core/Card.jsx":"f5a0683ba477","components/core/Input.jsx":"f58a4d7ed385","components/core/ListRow.jsx":"ab0f5c88c23d","components/core/ProgressRing.jsx":"c122d15de5bc","components/core/SegmentedControl.jsx":"8fc05b383f40","components/core/StatTile.jsx":"8d2ff29168b0","components/core/Toggle.jsx":"778c8deef334","components/finance/Coin.jsx":"f8ebf29c664c","components/finance/CreditCard3D.jsx":"09acc446c799","ui_kits/app/app.jsx":"cbcc97e9187f","ui_kits/app/kit.jsx":"0b7d154fd3cf","ui_kits/app/screens.jsx":"2307d8428a11","ui_kits/site/landing.jsx":"6019caa135c4"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.SterlingPersonalCFODesignSystem_123495 = window.SterlingPersonalCFODesignSystem_123495 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Avatar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Avatar — user or merchant identity. Initials or image, with an optional
 * ring and status dot. Merchant variant uses a rounded square.
 */
function Avatar({
  name = '',
  src = null,
  size = 44,
  shape = 'circle',
  tone = 'mint',
  ring = false,
  status = null,
  style,
  ...rest
}) {
  const tones = {
    mint: 'var(--grad-mint)',
    gold: 'var(--grad-gold-metal)',
    violet: 'var(--grad-violet-card)',
    ink: 'var(--grad-obsidian)',
    blue: 'linear-gradient(140deg,#4d86f0,#1a61e9)'
  };
  const initials = name.split(' ').map(w => w[0]).filter(Boolean).slice(0, 2).join('').toUpperCase();
  const radius = shape === 'circle' ? '50%' : 'calc(var(--radius-md) * 1)';
  const statusColors = {
    online: 'var(--gain)',
    away: 'var(--warn)',
    off: 'var(--paper-faint)'
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      display: 'inline-flex',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      width: size,
      height: size,
      borderRadius: radius,
      background: src ? 'var(--ink-500)' : tones[tone],
      color: 'var(--ink-900)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'var(--font-sans)',
      fontWeight: 800,
      fontSize: size * 0.38,
      letterSpacing: '-0.02em',
      overflow: 'hidden',
      border: ring ? '2px solid var(--mint-400)' : 'none',
      boxShadow: ring ? 'var(--glow-mint)' : 'inset 0 1px 0 rgba(255,255,255,0.2)'
    }
  }, src ? /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: name,
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover'
    }
  }) : initials), status && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      right: -1,
      bottom: -1,
      width: size * 0.28,
      height: size * 0.28,
      borderRadius: '50%',
      background: statusColors[status] || statusColors.off,
      border: '2px solid var(--surface-card)'
    }
  }));
}
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Badge — small status pill for state and finance signals.
 */
function Badge({
  children,
  tone = 'neutral',
  solid = false,
  dot = false,
  style,
  ...rest
}) {
  const tones = {
    neutral: {
      fg: 'var(--text-secondary)',
      bg: 'rgba(255,255,255,0.07)',
      solidBg: 'var(--ink-300)',
      solidFg: 'var(--paper)'
    },
    mint: {
      fg: 'var(--mint-300)',
      bg: 'rgba(34,230,164,0.12)',
      solidBg: 'var(--mint-500)',
      solidFg: 'var(--ink-900)'
    },
    gain: {
      fg: 'var(--gain)',
      bg: 'rgba(34,230,164,0.12)',
      solidBg: 'var(--gain)',
      solidFg: 'var(--ink-900)'
    },
    loss: {
      fg: 'var(--loss)',
      bg: 'rgba(238,47,76,0.14)',
      solidBg: 'var(--loss)',
      solidFg: 'var(--paper)'
    },
    warn: {
      fg: 'var(--warn)',
      bg: 'rgba(245,165,36,0.14)',
      solidBg: 'var(--warn)',
      solidFg: 'var(--ink-900)'
    },
    info: {
      fg: 'var(--info)',
      bg: 'rgba(77,134,240,0.14)',
      solidBg: 'var(--info)',
      solidFg: 'var(--paper)'
    },
    gold: {
      fg: 'var(--gold-400)',
      bg: 'rgba(232,200,126,0.14)',
      solidBg: 'var(--gold-400)',
      solidFg: 'var(--ink-900)'
    }
  };
  const t = tones[tone] || tones.neutral;
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      padding: '4px 11px',
      fontFamily: 'var(--font-sans)',
      fontSize: 12,
      fontWeight: 700,
      letterSpacing: '0.01em',
      borderRadius: 'var(--radius-pill)',
      background: solid ? t.solidBg : t.bg,
      color: solid ? t.solidFg : t.fg,
      whiteSpace: 'nowrap',
      ...style
    }
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: 999,
      background: 'currentColor'
    }
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — Sterling's primary action. Pill-shaped by default (the CRED
 * signature), with a luminous mint fill for primary intent.
 */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  block = false,
  disabled = false,
  icon = null,
  iconRight = null,
  type = 'button',
  onClick,
  style,
  ...rest
}) {
  const sizes = {
    sm: {
      padding: '10px 20px',
      fontSize: 14,
      gap: 8
    },
    md: {
      padding: '15px 30px',
      fontSize: 16,
      gap: 10
    },
    lg: {
      padding: '19px 42px',
      fontSize: 18,
      gap: 12
    }
  };
  const base = {
    display: block ? 'flex' : 'inline-flex',
    width: block ? '100%' : 'auto',
    alignItems: 'center',
    justifyContent: 'center',
    gap: sizes[size].gap,
    padding: sizes[size].padding,
    fontFamily: 'var(--font-sans)',
    fontWeight: 700,
    fontSize: sizes[size].fontSize,
    lineHeight: 1,
    letterSpacing: '-0.01em',
    borderRadius: 'var(--radius-pill)',
    border: '1px solid transparent',
    cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'transform var(--dur-quick) var(--ease-out), background var(--dur-quick) var(--ease-out), box-shadow var(--dur-quick) var(--ease-out), filter var(--dur-quick) var(--ease-out)',
    whiteSpace: 'nowrap',
    userSelect: 'none',
    WebkitTapHighlightColor: 'transparent'
  };
  const variants = {
    primary: {
      background: 'var(--grad-mint)',
      color: 'var(--on-accent)',
      boxShadow: 'var(--glow-mint), inset 0 1px 0 rgba(255,255,255,0.35)'
    },
    secondary: {
      background: 'var(--paper)',
      color: 'var(--ink-900)',
      boxShadow: '0 6px 20px rgba(0,0,0,0.4)'
    },
    ghost: {
      background: 'var(--surface-input)',
      color: 'var(--text-primary)',
      border: '1px solid var(--border-soft)'
    },
    outline: {
      background: 'transparent',
      color: 'var(--accent)',
      border: '1.5px solid var(--border-accent)'
    },
    danger: {
      background: 'var(--loss)',
      color: 'var(--paper)',
      boxShadow: 'var(--glow-loss)'
    }
  };
  const [pressed, setPressed] = React.useState(false);
  const [hover, setHover] = React.useState(false);
  const dynamic = disabled ? {} : {
    transform: pressed ? 'scale(0.97)' : hover ? 'translateY(-2px)' : 'none',
    filter: hover ? 'brightness(1.06)' : 'none'
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: type,
    disabled: disabled,
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPressed(false);
    },
    onMouseDown: () => setPressed(true),
    onMouseUp: () => setPressed(false),
    style: {
      ...base,
      ...variants[variant],
      ...dynamic,
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      fontSize: '1.15em'
    }
  }, icon), children, iconRight && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      fontSize: '1.15em'
    }
  }, iconRight));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Card — the default Sterling surface. Dark ink fill, hairline top
 * highlight + drop shadow (the "lift"). Optional glass and glow.
 */
function Card({
  children,
  variant = 'default',
  padding = 20,
  glow = false,
  interactive = false,
  style,
  ...rest
}) {
  const variants = {
    default: {
      background: 'var(--surface-card)',
      border: '1px solid var(--border-subtle)',
      boxShadow: 'var(--lift-card)'
    },
    elevated: {
      background: 'var(--surface-elev)',
      border: '1px solid var(--border-soft)',
      boxShadow: 'var(--lift-raised)'
    },
    glass: {
      background: 'var(--glass-fill)',
      WebkitBackdropFilter: 'blur(var(--glass-blur))',
      backdropFilter: 'blur(var(--glass-blur))',
      border: '1px solid var(--glass-border)',
      boxShadow: 'var(--lift-raised)'
    },
    outline: {
      background: 'transparent',
      border: '1px solid var(--border-strong)'
    }
  };
  const [hover, setHover] = React.useState(false);
  const base = {
    borderRadius: 'var(--radius-lg)',
    padding: typeof padding === 'number' ? `${padding}px` : padding,
    position: 'relative',
    transition: 'transform var(--dur-base) var(--ease-out), box-shadow var(--dur-base) var(--ease-out)',
    ...(glow ? {
      boxShadow: `${variants[variant].boxShadow || ''}, var(--glow-mint)`
    } : {}),
    ...(interactive && hover ? {
      transform: 'translateY(-4px)'
    } : {}),
    cursor: interactive ? 'pointer' : 'default'
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      ...variants[variant],
      ...base,
      ...style
    },
    onMouseEnter: () => interactive && setHover(true),
    onMouseLeave: () => interactive && setHover(false)
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Input — text field with dark fill, mint focus ring. Optional label,
 * leading/trailing adornments, and error state.
 */
function Input({
  label = null,
  hint = null,
  error = null,
  prefix = null,
  suffix = null,
  size = 'md',
  style,
  containerStyle,
  disabled = false,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  const sizes = {
    sm: {
      h: 42,
      fs: 14,
      px: 14
    },
    md: {
      h: 52,
      fs: 16,
      px: 16
    },
    lg: {
      h: 60,
      fs: 18,
      px: 18
    }
  };
  const s = sizes[size];
  const borderColor = error ? 'var(--loss)' : focus ? 'var(--mint-400)' : 'var(--border-soft)';
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      ...containerStyle
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 13,
      fontWeight: 600,
      color: 'var(--text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      height: s.h,
      padding: `0 ${s.px}px`,
      background: 'var(--surface-input)',
      border: `1.5px solid ${borderColor}`,
      borderRadius: 'var(--radius-md)',
      boxShadow: focus && !error ? 'var(--glow-mint)' : 'none',
      transition: 'border-color var(--dur-quick) var(--ease-out), box-shadow var(--dur-quick) var(--ease-out)',
      opacity: disabled ? 0.5 : 1
    }
  }, prefix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-tertiary)',
      display: 'inline-flex',
      fontWeight: 700
    }
  }, prefix), /*#__PURE__*/React.createElement("input", _extends({
    disabled: disabled,
    onFocus: e => {
      setFocus(true);
      rest.onFocus && rest.onFocus(e);
    },
    onBlur: e => {
      setFocus(false);
      rest.onBlur && rest.onBlur(e);
    },
    style: {
      flex: 1,
      minWidth: 0,
      background: 'transparent',
      border: 'none',
      outline: 'none',
      fontFamily: 'var(--font-sans)',
      fontSize: s.fs,
      fontWeight: 600,
      color: 'var(--text-primary)',
      ...style
    }
  }, rest)), suffix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-tertiary)',
      display: 'inline-flex',
      fontWeight: 700
    }
  }, suffix)), (hint || error) && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 12,
      fontWeight: 500,
      color: error ? 'var(--loss)' : 'var(--text-tertiary)'
    }
  }, error || hint));
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Input.jsx", error: String((e && e.message) || e) }); }

// components/core/ListRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ListRow — a transaction / account row: leading avatar or icon, title +
 * subtitle, and a right-aligned amount with optional meta.
 */
function ListRow({
  title,
  subtitle = null,
  amount = null,
  amountTone = 'default',
  meta = null,
  avatarName = null,
  avatarSrc = null,
  avatarShape = 'square',
  avatarTone = 'ink',
  leading = null,
  trailing = null,
  onClick,
  divider = false,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const amtColors = {
    default: 'var(--text-primary)',
    gain: 'var(--gain)',
    loss: 'var(--loss)'
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 14px',
      borderRadius: 'var(--radius-md)',
      background: hover && onClick ? 'var(--surface-hover)' : 'transparent',
      borderBottom: divider ? '1px solid var(--border-subtle)' : 'none',
      cursor: onClick ? 'pointer' : 'default',
      transition: 'background var(--dur-quick) var(--ease-out)',
      ...style
    }
  }, rest), leading || (avatarName || avatarSrc ? /*#__PURE__*/React.createElement(__ds_scope.Avatar, {
    name: avatarName || '',
    src: avatarSrc,
    shape: avatarShape,
    tone: avatarTone,
    size: 44
  }) : null), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      display: 'flex',
      flexDirection: 'column',
      gap: 3
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 15,
      fontWeight: 700,
      color: 'var(--text-primary)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 13,
      fontWeight: 500,
      color: 'var(--text-tertiary)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, subtitle)), trailing || /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'flex-end',
      gap: 3
    }
  }, amount != null && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 15,
      fontWeight: 800,
      color: amtColors[amountTone],
      fontVariantNumeric: 'tabular-nums'
    }
  }, amount), meta && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 12,
      fontWeight: 500,
      color: 'var(--text-tertiary)'
    }
  }, meta)));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/core/ProgressRing.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProgressRing — circular progress for budgets & goals. SVG arc with a
 * mint (or tone) gradient stroke and a value in the centre.
 */
function ProgressRing({
  value = 0,
  max = 100,
  size = 120,
  thickness = 12,
  tone = 'mint',
  label = null,
  caption = null,
  style,
  ...rest
}) {
  const pct = Math.max(0, Math.min(1, value / max));
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const gradId = React.useId ? React.useId() : `ring-${Math.random().toString(36).slice(2)}`;
  const tones = {
    mint: ['#2af0b0', '#00d492'],
    gold: ['#f7e6b8', '#d4af58'],
    loss: ['#ff6b81', '#ee2f4c'],
    blue: ['#4d86f0', '#1a61e9'],
    violet: ['#8b6bf2', '#5a1ecb']
  };
  const [a, b] = tones[tone] || tones.mint;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      width: size,
      height: size,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    style: {
      transform: 'rotate(-90deg)'
    }
  }, /*#__PURE__*/React.createElement("defs", null, /*#__PURE__*/React.createElement("linearGradient", {
    id: gradId,
    x1: "0%",
    y1: "0%",
    x2: "100%",
    y2: "100%"
  }, /*#__PURE__*/React.createElement("stop", {
    offset: "0%",
    stopColor: a
  }), /*#__PURE__*/React.createElement("stop", {
    offset: "100%",
    stopColor: b
  }))), /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: "var(--ink-400)",
    strokeWidth: thickness
  }), /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: `url(#${gradId})`,
    strokeWidth: thickness,
    strokeLinecap: "round",
    strokeDasharray: c,
    strokeDashoffset: c * (1 - pct),
    style: {
      transition: 'stroke-dashoffset var(--dur-slow) var(--ease-out)',
      filter: `drop-shadow(0 0 6px ${b}66)`
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 2
    }
  }, label != null && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontWeight: 800,
      fontSize: size * 0.24,
      color: 'var(--text-primary)',
      fontVariantNumeric: 'tabular-nums',
      letterSpacing: '-0.02em'
    }
  }, label), caption && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontWeight: 600,
      fontSize: size * 0.1,
      color: 'var(--text-tertiary)'
    }
  }, caption)));
}
Object.assign(__ds_scope, { ProgressRing });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ProgressRing.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * SegmentedControl — pill-track tab switcher (e.g. week / month / year).
 * The active thumb slides with spring easing.
 */
function SegmentedControl({
  options = [],
  value,
  onChange,
  size = 'md',
  style,
  ...rest
}) {
  const items = options.map(o => typeof o === 'string' ? {
    value: o,
    label: o
  } : o);
  const activeIndex = Math.max(0, items.findIndex(it => it.value === value));
  const sizes = {
    sm: {
      h: 36,
      fs: 13,
      pad: 4
    },
    md: {
      h: 44,
      fs: 14,
      pad: 5
    }
  };
  const s = sizes[size];
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      display: 'grid',
      gridTemplateColumns: `repeat(${items.length}, 1fr)`,
      height: s.h,
      padding: s.pad,
      background: 'var(--ink-700)',
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-pill)',
      boxShadow: 'inset 0 1px 3px rgba(0,0,0,0.5)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: s.pad,
      bottom: s.pad,
      left: `calc(${s.pad}px + ${activeIndex} * ((100% - ${s.pad * 2}px) / ${items.length}))`,
      width: `calc((100% - ${s.pad * 2}px) / ${items.length})`,
      background: 'var(--surface-hover)',
      borderRadius: 'var(--radius-pill)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.08), 0 2px 6px rgba(0,0,0,0.4)',
      transition: 'left var(--dur-base) var(--ease-spring)'
    }
  }), items.map(it => {
    const active = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      onClick: () => onChange && onChange(it.value),
      style: {
        position: 'relative',
        zIndex: 1,
        background: 'transparent',
        border: 'none',
        cursor: 'pointer',
        fontFamily: 'var(--font-sans)',
        fontSize: s.fs,
        fontWeight: active ? 700 : 600,
        color: active ? 'var(--text-primary)' : 'var(--text-tertiary)',
        transition: 'color var(--dur-quick) var(--ease-out)',
        whiteSpace: 'nowrap'
      }
    }, it.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/core/StatTile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StatTile — a KPI / metric card: eyebrow label, big tabular figure, and a
 * delta chip. Optional accent glow for the primary metric.
 */
function StatTile({
  label,
  value,
  delta = null,
  deltaTone = 'gain',
  icon = null,
  accent = false,
  style,
  ...rest
}) {
  const deltaColors = {
    gain: {
      fg: 'var(--gain)',
      bg: 'rgba(34,230,164,0.12)'
    },
    loss: {
      fg: 'var(--loss)',
      bg: 'rgba(238,47,76,0.14)'
    },
    neutral: {
      fg: 'var(--text-secondary)',
      bg: 'rgba(255,255,255,0.07)'
    }
  };
  const dc = deltaColors[deltaTone] || deltaColors.neutral;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      padding: 20,
      background: accent ? 'var(--grad-mint-soft)' : 'var(--surface-card)',
      border: `1px solid ${accent ? 'rgba(34,230,164,0.28)' : 'var(--border-subtle)'}`,
      borderRadius: 'var(--radius-lg)',
      boxShadow: accent ? 'var(--lift-card), var(--glow-mint)' : 'var(--lift-card)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 11,
      fontWeight: 600,
      letterSpacing: '0.12em',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, label), icon && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-tertiary)',
      display: 'inline-flex',
      fontSize: 18
    }
  }, icon)), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 30,
      fontWeight: 800,
      letterSpacing: '-0.02em',
      color: 'var(--text-primary)',
      fontVariantNumeric: 'tabular-nums',
      lineHeight: 1
    }
  }, value), delta != null && /*#__PURE__*/React.createElement("span", {
    style: {
      alignSelf: 'flex-start',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      padding: '4px 10px',
      borderRadius: 'var(--radius-pill)',
      background: dc.bg,
      color: dc.fg,
      fontFamily: 'var(--font-sans)',
      fontSize: 12,
      fontWeight: 700
    }
  }, deltaTone === 'gain' ? '▲' : deltaTone === 'loss' ? '▼' : '', " ", delta));
}
Object.assign(__ds_scope, { StatTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/StatTile.jsx", error: String((e && e.message) || e) }); }

// components/core/Toggle.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Toggle — on/off switch. Mint fill + glow when on, weighted spring motion.
 */
function Toggle({
  checked = false,
  onChange,
  disabled = false,
  size = 'md',
  style,
  ...rest
}) {
  const sizes = {
    sm: {
      w: 40,
      h: 24,
      k: 18
    },
    md: {
      w: 52,
      h: 30,
      k: 24
    }
  };
  const s = sizes[size];
  const pad = (s.h - s.k) / 2;
  return /*#__PURE__*/React.createElement("button", _extends({
    role: "switch",
    "aria-checked": checked,
    disabled: disabled,
    onClick: () => !disabled && onChange && onChange(!checked),
    style: {
      position: 'relative',
      width: s.w,
      height: s.h,
      padding: 0,
      border: 'none',
      cursor: disabled ? 'not-allowed' : 'pointer',
      borderRadius: 'var(--radius-pill)',
      background: checked ? 'var(--grad-mint)' : 'var(--ink-400)',
      boxShadow: checked ? 'var(--glow-mint), inset 0 1px 2px rgba(0,0,0,0.3)' : 'inset 0 1px 3px rgba(0,0,0,0.5)',
      opacity: disabled ? 0.5 : 1,
      transition: 'background var(--dur-base) var(--ease-out), box-shadow var(--dur-base) var(--ease-out)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: pad,
      left: checked ? s.w - s.k - pad : pad,
      width: s.k,
      height: s.k,
      borderRadius: '50%',
      background: checked ? 'var(--ink-900)' : 'var(--paper)',
      boxShadow: '0 2px 6px rgba(0,0,0,0.5)',
      transition: 'left var(--dur-base) var(--ease-spring)'
    }
  }));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/finance/Coin.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Coin — a 3D reward coin. Metallic disc with a raised rim, symbol face, and
 * a glow. Sterling's rewards currency motif (à la CRED coins). Optional spin.
 */
function Coin({
  symbol = '$',
  size = 96,
  tone = 'gold',
  spin = false,
  glow = true,
  style,
  ...rest
}) {
  const tones = {
    gold: {
      face: 'radial-gradient(60% 60% at 35% 30%, #fff3cf 0%, #e8c87e 42%, #b98f3f 100%)',
      rim: '#8a6a2c',
      text: '#6a4e18',
      glow: 'var(--glow-gold)'
    },
    mint: {
      face: 'radial-gradient(60% 60% at 35% 30%, #b9ffe6 0%, #22e6a4 44%, #04936a 100%)',
      rim: '#036e4f',
      text: '#023b2b',
      glow: 'var(--glow-mint)'
    },
    silver: {
      face: 'radial-gradient(60% 60% at 35% 30%, #ffffff 0%, #cfd4dc 45%, #8a909c 100%)',
      rim: '#6a707c',
      text: '#3a3f49',
      glow: '0 0 40px -6px rgba(207,212,220,0.5)'
    }
  };
  const t = tones[tone] || tones.gold;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      width: size,
      height: size,
      position: 'relative',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: '50%',
      background: t.face,
      boxShadow: `inset 0 ${size * 0.03}px ${size * 0.05}px rgba(255,255,255,0.6), inset 0 -${size * 0.04}px ${size * 0.06}px rgba(0,0,0,0.35), 0 ${size * 0.08}px ${size * 0.14}px rgba(0,0,0,0.5)${glow ? `, ${t.glow}` : ''}`,
      border: `${Math.max(2, size * 0.03)}px solid ${t.rim}`,
      animation: spin ? 'coin-spin 3.2s linear infinite' : 'none',
      transformStyle: 'preserve-3d',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: size * 0.11,
      borderRadius: '50%',
      border: `${Math.max(1, size * 0.012)}px dashed ${t.rim}55`
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontWeight: 900,
      fontSize: size * 0.44,
      color: t.text,
      textShadow: '0 1px 0 rgba(255,255,255,0.4)',
      letterSpacing: '-0.03em'
    }
  }, symbol));
}
Object.assign(__ds_scope, { Coin });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/finance/Coin.jsx", error: String((e && e.message) || e) }); }

// components/finance/CreditCard3D.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * CreditCard3D — Sterling's signature object. A metallic payment card that
 * tilts toward the cursor (parallax), with a swept sheen, embossed chip, and
 * layered depth. Interactive by default; pass `interactive={false}` for a
 * static hero card that keeps a fixed 3D pose.
 */
function CreditCard3D({
  scheme = 'obsidian',
  label = 'sterling',
  tier = 'metal',
  holder = 'A. LOVELACE',
  last4 = '4291',
  network = 'visa',
  balance = null,
  width = 340,
  interactive = true,
  float = false,
  style,
  ...rest
}) {
  const ref = React.useRef(null);
  const [tilt, setTilt] = React.useState({
    x: 8,
    y: -16
  });
  const schemes = {
    obsidian: {
      bg: 'var(--grad-obsidian)',
      fg: '#f4f4f6',
      sub: 'rgba(244,244,246,0.6)',
      accent: 'var(--mint-400)'
    },
    emerald: {
      bg: 'var(--grad-emerald-card)',
      fg: '#eafff6',
      sub: 'rgba(234,255,246,0.65)',
      accent: '#8affd8'
    },
    gold: {
      bg: 'var(--grad-gold-metal)',
      fg: '#2a2110',
      sub: 'rgba(42,33,16,0.7)',
      accent: '#5a3d0c'
    },
    violet: {
      bg: 'var(--grad-violet-card)',
      fg: '#f2ecff',
      sub: 'rgba(242,236,255,0.65)',
      accent: '#c9b4ff'
    }
  };
  const s = schemes[scheme] || schemes.obsidian;
  const height = width / 1.586; // ISO 7810 card ratio

  const onMove = e => {
    if (!interactive || !ref.current) return;
    const r = ref.current.getBoundingClientRect();
    const px = (e.clientX - r.left) / r.width - 0.5;
    const py = (e.clientY - r.top) / r.height - 0.5;
    setTilt({
      x: -py * 18,
      y: px * 26
    });
  };
  const onLeave = () => interactive && setTilt({
    x: 8,
    y: -16
  });
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      perspective: 1200,
      width,
      ...style
    },
    onMouseMove: onMove,
    onMouseLeave: onLeave
  }, rest), /*#__PURE__*/React.createElement("div", {
    ref: ref,
    style: {
      position: 'relative',
      width,
      height,
      borderRadius: 'var(--radius-card-face)',
      background: s.bg,
      color: s.fg,
      transformStyle: 'preserve-3d',
      transform: `rotateX(${tilt.x}deg) rotateY(${tilt.y}deg)`,
      transition: interactive ? 'transform 120ms var(--ease-out)' : 'none',
      boxShadow: '0 30px 60px -18px rgba(0,0,0,0.75), inset 0 1px 0 rgba(255,255,255,0.35), inset 0 -1px 0 rgba(0,0,0,0.5)',
      overflow: 'hidden',
      animation: float ? 'float-y 5s var(--ease-in-out) infinite' : 'none',
      fontFamily: 'var(--font-sans)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: '-40% -10%',
      background: 'var(--grad-sheen)',
      pointerEvents: 'none',
      mixBlendMode: 'overlay'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'radial-gradient(80% 60% at 20% 0%, rgba(255,255,255,0.18), transparent 60%)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: height * 0.11,
      left: width * 0.07,
      right: width * 0.07,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: width * 0.062,
      fontWeight: 800,
      letterSpacing: '-0.02em'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: width * 0.032,
      fontWeight: 700,
      letterSpacing: '0.18em',
      textTransform: 'uppercase',
      color: s.sub
    }
  }, tier)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: height * 0.34,
      left: width * 0.07,
      width: width * 0.135,
      height: width * 0.105,
      borderRadius: width * 0.02,
      background: 'linear-gradient(135deg,#f7e6b8,#d4af58 55%,#a9843a)',
      boxShadow: 'inset 0 0 0 1px rgba(0,0,0,0.25)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: '30% 12%',
      borderTop: '1px solid rgba(0,0,0,0.3)',
      borderBottom: '1px solid rgba(0,0,0,0.3)'
    }
  })), balance != null && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: height * 0.34,
      right: width * 0.07,
      textAlign: 'right'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: width * 0.03,
      fontWeight: 600,
      letterSpacing: '0.1em',
      textTransform: 'uppercase',
      color: s.sub
    }
  }, "balance"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: width * 0.062,
      fontWeight: 800,
      fontVariantNumeric: 'tabular-nums',
      letterSpacing: '-0.02em'
    }
  }, balance)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: height * 0.26,
      left: width * 0.07,
      fontSize: width * 0.062,
      fontWeight: 700,
      letterSpacing: '0.12em',
      fontVariantNumeric: 'tabular-nums'
    }
  }, "\u2022\u2022\u2022\u2022\xA0\xA0\u2022\u2022\u2022\u2022\xA0\xA0\u2022\u2022\u2022\u2022\xA0\xA0", last4), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: height * 0.09,
      left: width * 0.07,
      right: width * 0.07,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: width * 0.038,
      fontWeight: 700,
      letterSpacing: '0.08em',
      color: s.sub
    }
  }, holder), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: width * 0.058,
      fontWeight: 800,
      fontStyle: 'italic',
      letterSpacing: '-0.03em'
    }
  }, network))));
}
Object.assign(__ds_scope, { CreditCard3D });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/finance/CreditCard3D.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/app.jsx
try { (() => {
/* Sterling app — interactive shell: device frame, status bar, glass tab bar,
   screen routing, login gate. Mounts to #root. */

const Icon2 = window.Icon;
function StatusBar({
  dark
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '14px 26px 4px',
      fontSize: 14,
      fontWeight: 700,
      color: 'var(--text-primary)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontVariantNumeric: 'tabular-nums'
    }
  }, "9:41"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 7,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Icon2, {
    name: "signal",
    size: 16
  }), /*#__PURE__*/React.createElement(Icon2, {
    name: "wifi",
    size: 16
  }), /*#__PURE__*/React.createElement(Icon2, {
    name: "battery-full",
    size: 18
  })));
}
const TABS = [{
  id: 'home',
  icon: 'home',
  label: 'home'
}, {
  id: 'cards',
  icon: 'credit-card',
  label: 'cards'
}, {
  id: 'spending',
  icon: 'pie-chart',
  label: 'spending'
}, {
  id: 'rewards',
  icon: 'gift',
  label: 'rewards'
}];
function TabBar({
  tab,
  setTab
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 12,
      right: 12,
      bottom: 12,
      display: 'grid',
      gridTemplateColumns: 'repeat(4,1fr)',
      padding: '10px 8px 12px',
      background: 'var(--glass-fill)',
      WebkitBackdropFilter: 'blur(var(--glass-blur-strong))',
      backdropFilter: 'blur(var(--glass-blur-strong))',
      border: '1px solid var(--glass-border)',
      borderRadius: 'var(--radius-2xl)',
      boxShadow: 'var(--lift-raised)',
      zIndex: 20
    }
  }, TABS.map(t => {
    const on = tab === t.id;
    return /*#__PURE__*/React.createElement("button", {
      key: t.id,
      onClick: () => setTab(t.id),
      style: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 5,
        background: 'transparent',
        border: 'none',
        cursor: 'pointer',
        padding: '4px 0'
      }
    }, /*#__PURE__*/React.createElement(Icon2, {
      name: t.icon,
      size: 23,
      color: on ? 'var(--mint-400)' : 'var(--text-tertiary)',
      strokeWidth: on ? 2.4 : 2
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 10.5,
        fontWeight: 700,
        letterSpacing: '0.02em',
        color: on ? 'var(--mint-400)' : 'var(--text-tertiary)'
      }
    }, t.label));
  }));
}
function App() {
  const [authed, setAuthed] = React.useState(false);
  const [tab, setTab] = React.useState('home');
  const scrollRef = React.useRef(null);
  React.useEffect(() => {
    window.refreshIcons && window.refreshIcons();
  });
  React.useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  }, [tab, authed]);
  const screens = {
    home: /*#__PURE__*/React.createElement(window.HomeScreen, {
      go: setTab
    }),
    cards: /*#__PURE__*/React.createElement(window.CardsScreen, null),
    spending: /*#__PURE__*/React.createElement(window.SpendingScreen, null),
    rewards: /*#__PURE__*/React.createElement(window.RewardsScreen, null)
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "phone"
  }, /*#__PURE__*/React.createElement("div", {
    className: "notch"
  }), /*#__PURE__*/React.createElement(StatusBar, null), /*#__PURE__*/React.createElement("div", {
    ref: scrollRef,
    className: "screen-scroll",
    style: {
      paddingBottom: authed ? 100 : 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '6px 18px 0',
      minHeight: authed ? 'auto' : 'calc(844px - 120px)'
    }
  }, authed ? screens[tab] : /*#__PURE__*/React.createElement(window.LoginScreen, {
    onDone: () => setAuthed(true)
  }))), authed && /*#__PURE__*/React.createElement(TabBar, {
    tab: tab,
    setTab: setTab
  }), /*#__PURE__*/React.createElement("div", {
    className: "home-indicator"
  }));
}
ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/kit.jsx
try { (() => {
/* Sterling Personal CFO — mobile app UI kit
   Screens + interactive shell. Composes design-system primitives from
   window.SterlingPersonalCFODesignSystem_123495 and Lucide icons.
   Everything attaches to window (loaded via <script type="text/babel">). */

const DS = window.SterlingPersonalCFODesignSystem_123495;

/* ---- Icon: build SVG from Lucide icon data (React-safe) ---- */
function toPascal(name) {
  return name.split('-').map(p => p.charAt(0).toUpperCase() + p.slice(1)).join('');
}
/* names that were renamed across lucide versions — try both */
const ICON_ALIASES = {
  home: ['Home', 'House'],
  house: ['House', 'Home'],
  'pie-chart': ['PieChart', 'ChartPie'],
  'chart-pie': ['ChartPie', 'PieChart']
};
function lucideNode(name) {
  const L = window.lucide || {};
  const store = L.icons || L;
  const candidates = ICON_ALIASES[name] || [toPascal(name)];
  for (const k of candidates) {
    if (store[k]) return store[k];
  }
  return store[toPascal(name)] || null;
}
function Icon({
  name,
  size = 22,
  color = 'currentColor',
  strokeWidth = 2,
  style
}) {
  const node = lucideNode(name);
  const base = {
    display: 'inline-block',
    width: size,
    height: size,
    flexShrink: 0,
    ...style
  };
  if (!node) return /*#__PURE__*/React.createElement("span", {
    style: base
  });
  return React.createElement('svg', {
    width: size,
    height: size,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: color,
    strokeWidth,
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    style: base
  }, node.map((child, i) => React.createElement(child[0], {
    key: i,
    ...child[1]
  })));
}
function refreshIcons() {/* no-op — icons render inline via React */}

/* ---- helpers -------------------------------------------- */
const money = n => (n < 0 ? '−' : '') + '$' + Math.abs(n).toLocaleString('en-US', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
window.Icon = Icon;
window.refreshIcons = refreshIcons;
window.money = money;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/kit.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/screens.jsx
try { (() => {
/* Sterling app — screens. Attaches HomeScreen, CardsScreen, SpendingScreen,
   RewardsScreen, LoginScreen + AppShell to window. */

const DS2 = window.SterlingPersonalCFODesignSystem_123495;
const {
  Button,
  Card,
  Badge,
  Avatar,
  Toggle,
  SegmentedControl,
  ProgressRing,
  StatTile,
  ListRow,
  CreditCard3D,
  Coin,
  Input
} = DS2;
const Icon = window.Icon;
const money = window.money;

/* ============================ DATA ============================ */
const TXNS = [{
  name: 'whole foods',
  cat: 'groceries',
  tone: 'mint',
  amt: -84.2,
  when: 'today'
}, {
  name: 'acme payroll',
  cat: 'income',
  tone: 'mint',
  amt: 4200,
  when: 'mar 1'
}, {
  name: 'netflix',
  cat: 'subscriptions',
  tone: 'violet',
  amt: -15.99,
  when: 'yesterday'
}, {
  name: 'shell',
  cat: 'transport',
  tone: 'gold',
  amt: -52.4,
  when: 'yesterday'
}, {
  name: 'apple',
  cat: 'shopping',
  tone: 'ink',
  amt: -129.0,
  when: 'feb 27'
}, {
  name: 'chase savings',
  cat: 'transfer',
  tone: 'blue',
  amt: -500,
  when: 'feb 26'
}];
const CATS = [{
  name: 'groceries',
  spent: 640,
  budget: 800,
  tone: 'mint'
}, {
  name: 'dining',
  spent: 512,
  budget: 500,
  tone: 'loss'
}, {
  name: 'transport',
  spent: 210,
  budget: 400,
  tone: 'blue'
}, {
  name: 'shopping',
  spent: 388,
  budget: 450,
  tone: 'violet'
}, {
  name: 'subscriptions',
  spent: 96,
  budget: 120,
  tone: 'gold'
}];
const REWARDS = [{
  title: 'amazon',
  sub: '₹500 voucher',
  cost: '4,000',
  tone: 'gold'
}, {
  title: 'uber',
  sub: '2 free rides',
  cost: '2,500',
  tone: 'mint'
}, {
  title: 'starbucks',
  sub: 'free grande',
  cost: '1,200',
  tone: 'violet'
}, {
  title: 'spotify',
  sub: '3 months',
  cost: '3,000',
  tone: 'blue'
}];

/* ============================ SHARED ============================ */
function ScreenHeader({
  title,
  sub,
  right
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      padding: '8px 4px 18px'
    }
  }, /*#__PURE__*/React.createElement("div", null, sub && /*#__PURE__*/React.createElement("div", {
    className: "t-eyebrow",
    style: {
      marginBottom: 6
    }
  }, sub), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 28,
      fontWeight: 800,
      letterSpacing: '-0.02em'
    }
  }, title)), right);
}
function SectionTitle({
  children,
  action
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      margin: '4px 4px 12px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 17,
      fontWeight: 700
    }
  }, children), action && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 600,
      color: 'var(--accent)'
    }
  }, action));
}

/* ============================ HOME ============================ */
function HomeScreen({
  go
}) {
  const [hide, setHide] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '6px 4px 20px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: "Ada Lovelace",
    ring: true,
    status: "online",
    size: 44
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "good evening,"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 800
    }
  }, "ada"))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 42,
      height: 42,
      borderRadius: 999,
      background: 'var(--surface-input)',
      border: '1px solid var(--border-soft)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "bell",
    size: 20,
    color: "var(--text-secondary)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 8,
      right: 9,
      width: 8,
      height: 8,
      borderRadius: 999,
      background: 'var(--mint-400)',
      boxShadow: 'var(--glow-mint)'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      overflow: 'hidden',
      background: 'var(--grad-mint-soft)',
      border: '1px solid rgba(34,230,164,0.24)',
      borderRadius: 'var(--radius-xl)',
      padding: 22,
      marginBottom: 18,
      boxShadow: 'var(--lift-card), var(--glow-mint)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: -30,
      top: -30,
      width: 160,
      height: 160,
      background: 'radial-gradient(circle,rgba(34,230,164,0.35),transparent 70%)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "t-eyebrow"
  }, "net worth"), /*#__PURE__*/React.createElement("button", {
    onClick: () => setHide(!hide),
    style: {
      background: 'transparent',
      border: 'none',
      cursor: 'pointer',
      color: 'var(--text-tertiary)',
      display: 'inline-flex'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: hide ? 'eye-off' : 'eye',
    size: 18
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 44,
      fontWeight: 800,
      letterSpacing: '-0.03em',
      margin: '8px 0 4px',
      fontVariantNumeric: 'tabular-nums'
    }
  }, hide ? '••••••' : '$48,210', /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 24,
      color: 'var(--text-tertiary)'
    }
  }, hide ? '' : '.75')), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "gain",
    dot: true
  }, "+$1,240 this month"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "+2.6%"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12,
      marginBottom: 22
    }
  }, /*#__PURE__*/React.createElement(StatTile, {
    label: "income",
    value: "$5,400",
    delta: "6%",
    deltaTone: "gain"
  }), /*#__PURE__*/React.createElement(StatTile, {
    label: "spent",
    value: "$3,204",
    delta: "8%",
    deltaTone: "loss"
  })), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "manage"
  }, "your cards"), /*#__PURE__*/React.createElement("div", {
    onClick: () => go('cards'),
    style: {
      display: 'flex',
      justifyContent: 'center',
      padding: '4px 0 26px',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(CreditCard3D, {
    scheme: "obsidian",
    holder: "A. LOVELACE",
    last4: "4291",
    balance: "$12,480",
    width: 300
  })), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "details"
  }, "this month"), /*#__PURE__*/React.createElement(Card, {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      marginBottom: 22
    }
  }, /*#__PURE__*/React.createElement(ProgressRing, {
    value: 68,
    label: "68%",
    caption: "of budget",
    size: 104
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 700,
      marginBottom: 6
    }
  }, "on track"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)',
      lineHeight: 1.5
    }
  }, "you've spent $3,204 of your $4,700 budget. nice pace."))), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "see all"
  }, "recent activity"), /*#__PURE__*/React.createElement(Card, {
    padding: 8
  }, TXNS.slice(0, 4).map((t, i) => /*#__PURE__*/React.createElement(ListRow, {
    key: i,
    avatarName: t.name,
    avatarTone: t.tone,
    title: t.name,
    subtitle: `${t.cat} · ${t.when}`,
    amount: money(t.amt),
    amountTone: t.amt < 0 ? 'loss' : 'gain',
    divider: i < 3
  }))));
}

/* ============================ CARDS ============================ */
function CardsScreen() {
  const [active, setActive] = React.useState(0);
  const [frozen, setFrozen] = React.useState(false);
  const cards = [{
    scheme: 'obsidian',
    tier: 'metal',
    last4: '4291',
    balance: '$12,480',
    network: 'visa'
  }, {
    scheme: 'gold',
    tier: 'platinum',
    last4: '7702',
    balance: '$3,120',
    network: 'mastercard'
  }, {
    scheme: 'violet',
    tier: 'signature',
    last4: '1188',
    balance: '$640',
    network: 'visa'
  }];
  const c = cards[active];
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(ScreenHeader, {
    title: "wallet",
    sub: "3 cards",
    right: /*#__PURE__*/React.createElement("span", {
      style: {
        width: 42,
        height: 42,
        borderRadius: 999,
        background: 'var(--grad-mint)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: 'var(--glow-mint)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "plus",
      size: 22,
      color: "var(--ink-900)",
      strokeWidth: 2.5
    }))
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      padding: '10px 0 22px'
    }
  }, /*#__PURE__*/React.createElement(CreditCard3D, {
    scheme: c.scheme,
    tier: c.tier,
    holder: "A. LOVELACE",
    last4: c.last4,
    balance: c.balance,
    network: c.network,
    width: 320
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      justifyContent: 'center',
      marginBottom: 24
    }
  }, cards.map((_, i) => /*#__PURE__*/React.createElement("button", {
    key: i,
    onClick: () => setActive(i),
    style: {
      width: i === active ? 26 : 8,
      height: 8,
      borderRadius: 999,
      border: 'none',
      cursor: 'pointer',
      background: i === active ? 'var(--mint-400)' : 'var(--ink-300)',
      transition: 'all var(--dur-base) var(--ease-out)'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr 1fr',
      gap: 12,
      marginBottom: 22
    }
  }, [{
    i: 'snowflake',
    l: frozen ? 'frozen' : 'freeze',
    on: frozen,
    act: () => setFrozen(!frozen)
  }, {
    i: 'settings-2',
    l: 'controls',
    act: () => {}
  }, {
    i: 'send',
    l: 'send',
    act: () => {}
  }].map((a, k) => /*#__PURE__*/React.createElement("button", {
    key: k,
    onClick: a.act,
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 8,
      padding: '16px 8px',
      borderRadius: 'var(--radius-lg)',
      cursor: 'pointer',
      background: a.on ? 'rgba(77,134,240,0.14)' : 'var(--surface-card)',
      border: `1px solid ${a.on ? 'var(--info)' : 'var(--border-subtle)'}`,
      boxShadow: 'var(--lift-card)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: a.i,
    size: 22,
    color: a.on ? 'var(--info)' : 'var(--text-secondary)'
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      fontWeight: 700,
      color: a.on ? 'var(--info)' : 'var(--text-secondary)'
    }
  }, a.l)))), /*#__PURE__*/React.createElement(SectionTitle, null, "card settings"), /*#__PURE__*/React.createElement(Card, {
    padding: 6
  }, /*#__PURE__*/React.createElement(SettingRow, {
    icon: "wifi",
    label: "contactless",
    defaultOn: true
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: "globe",
    label: "online payments",
    defaultOn: true,
    divider: true
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: "plane",
    label: "international"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 16
    }
  }), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "see all"
  }, "on this card"), /*#__PURE__*/React.createElement(Card, {
    padding: 8
  }, TXNS.slice(0, 3).map((t, i) => /*#__PURE__*/React.createElement(ListRow, {
    key: i,
    avatarName: t.name,
    avatarTone: t.tone,
    title: t.name,
    subtitle: `${t.cat} · ${t.when}`,
    amount: money(t.amt),
    amountTone: t.amt < 0 ? 'loss' : 'gain',
    divider: i < 2
  }))));
}
function SettingRow({
  icon,
  label,
  defaultOn = false,
  divider = false
}) {
  const [on, setOn] = React.useState(defaultOn);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 12px',
      borderBottom: divider ? '1px solid var(--border-subtle)' : 'none'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 38,
      height: 38,
      borderRadius: 'var(--radius-md)',
      background: 'var(--surface-input)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: icon,
    size: 19,
    color: "var(--text-secondary)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 15,
      fontWeight: 700
    }
  }, label), /*#__PURE__*/React.createElement(Toggle, {
    checked: on,
    onChange: setOn,
    size: "sm"
  }));
}

/* ============================ SPENDING ============================ */
function SpendingScreen() {
  const [range, setRange] = React.useState('month');
  const total = CATS.reduce((s, c) => s + c.spent, 0);
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(ScreenHeader, {
    title: "spending",
    sub: "insights"
  }), /*#__PURE__*/React.createElement(SegmentedControl, {
    options: ['week', 'month', 'year'],
    value: range,
    onChange: setRange
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 22
    }
  }), /*#__PURE__*/React.createElement(Card, {
    variant: "elevated",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 20,
      marginBottom: 22
    }
  }, /*#__PURE__*/React.createElement(ProgressRing, {
    value: total,
    max: 4700,
    label: money(-total).replace('−', ''),
    caption: "spent",
    size: 132,
    thickness: 14,
    tone: "loss"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "t-eyebrow",
    style: {
      marginBottom: 6
    }
  }, "vs last ", range), /*#__PURE__*/React.createElement(Badge, {
    tone: "loss",
    dot: true
  }, "+8% higher"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)',
      marginTop: 12,
      lineHeight: 1.5
    }
  }, "dining is over budget by $12."))), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "categorise"
  }, "by category"), /*#__PURE__*/React.createElement(Card, null, CATS.map((c, i) => {
    const pct = Math.min(1, c.spent / c.budget);
    const over = c.spent > c.budget;
    return /*#__PURE__*/React.createElement("div", {
      key: i,
      style: {
        marginBottom: i < CATS.length - 1 ? 18 : 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        justifyContent: 'space-between',
        marginBottom: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 14,
        fontWeight: 700
      }
    }, c.name), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 13,
        fontWeight: 700,
        color: over ? 'var(--loss)' : 'var(--text-secondary)',
        fontVariantNumeric: 'tabular-nums'
      }
    }, "$", c.spent, " ", /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--text-disabled)',
        fontWeight: 500
      }
    }, "/ $", c.budget))), /*#__PURE__*/React.createElement("div", {
      style: {
        height: 8,
        borderRadius: 999,
        background: 'var(--ink-400)',
        overflow: 'hidden'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: `${pct * 100}%`,
        height: '100%',
        borderRadius: 999,
        background: over ? 'var(--loss)' : `var(--${c.tone === 'mint' ? 'mint-400' : c.tone === 'loss' ? 'loss' : c.tone === 'blue' ? 'blue-500' : c.tone === 'violet' ? 'purple-500' : 'gold-400'})`,
        boxShadow: over ? 'var(--glow-loss)' : 'none',
        transition: 'width var(--dur-slow) var(--ease-out)'
      }
    })));
  })));
}

/* ============================ REWARDS ============================ */
function RewardsScreen() {
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(ScreenHeader, {
    title: "rewards",
    sub: "sterling coins"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      overflow: 'hidden',
      textAlign: 'center',
      padding: '24px 20px 28px',
      marginBottom: 24,
      background: 'var(--grad-obsidian)',
      border: '1px solid var(--border-soft)',
      borderRadius: 'var(--radius-2xl)',
      boxShadow: 'var(--lift-raised)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'var(--grad-aura-gold)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      display: 'flex',
      justifyContent: 'center',
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "$",
    tone: "gold",
    size: 92,
    spin: true
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      fontSize: 40,
      fontWeight: 800,
      letterSpacing: '-0.02em',
      fontVariantNumeric: 'tabular-nums'
    }
  }, "8,420"), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      fontSize: 13,
      color: 'var(--text-tertiary)',
      fontWeight: 600,
      marginTop: 2
    }
  }, "coins available"), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      fontSize: 12,
      fontWeight: 600,
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--gold-400)'
    }
  }, "gold tier"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-tertiary)'
    }
  }, "1,580 to platinum")), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 8,
      borderRadius: 999,
      background: 'var(--ink-400)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: '72%',
      height: '100%',
      background: 'var(--grad-gold-metal)',
      borderRadius: 999
    }
  })))), /*#__PURE__*/React.createElement(SectionTitle, {
    action: "see all"
  }, "redeem"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, REWARDS.map((r, i) => /*#__PURE__*/React.createElement(Card, {
    key: i,
    interactive: true,
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: r.title,
    shape: "square",
    tone: r.tone,
    size: 40
  }), /*#__PURE__*/React.createElement(Coin, {
    symbol: "$",
    tone: r.tone === 'gold' ? 'gold' : 'mint',
    size: 26,
    glow: false
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 700
    }
  }, r.title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-tertiary)',
      fontWeight: 500
    }
  }, r.sub)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 13,
      fontWeight: 800,
      color: 'var(--gold-400)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "coins",
    size: 15
  }), " ", r.cost)))));
}

/* ============================ LOGIN ============================ */
function LoginScreen({
  onDone
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      minHeight: '100%',
      padding: '10px 4px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      textAlign: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "S",
    tone: "mint",
    size: 78
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 40,
      fontWeight: 800,
      letterSpacing: '-0.03em'
    }
  }, "sterling"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 16,
      color: 'var(--text-secondary)',
      fontWeight: 600,
      maxWidth: 260,
      lineHeight: 1.5
    }
  }, "your personal CFO. every rupee, accounted for.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 14,
      paddingBottom: 10
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "mobile number",
    prefix: "+91",
    placeholder: "98765 43210"
  }), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "lg",
    block: true,
    onClick: onDone
  }, "get started"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 12,
      color: 'var(--text-tertiary)',
      lineHeight: 1.6
    }
  }, "by continuing you agree to our ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-link)'
    }
  }, "terms"), " & ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-link)'
    }
  }, "privacy policy"))));
}
window.HomeScreen = HomeScreen;
window.CardsScreen = CardsScreen;
window.SpendingScreen = SpendingScreen;
window.RewardsScreen = RewardsScreen;
window.LoginScreen = LoginScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/site/landing.jsx
try { (() => {
/* Sterling — marketing landing page. Recreates the CRED landing structure
   (claim bar → hero → 3D showcase → feature sections → ratings → footer),
   adapted to Sterling with 3D cards + coins. Mounts to #root. */

const DSL = window.SterlingPersonalCFODesignSystem_123495;
const {
  Button,
  CreditCard3D,
  Coin,
  Card,
  Badge,
  StatTile
} = DSL;
const IconL = window.Icon;
function Wrap({
  children,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      maxWidth: 1160,
      margin: '0 auto',
      padding: '0 28px',
      ...style
    }
  }, children);
}

/* ---- header + claim bar ---- */
function Header() {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--ink-600)',
      textAlign: 'center',
      padding: '13px 20px',
      fontSize: 15,
      fontWeight: 600,
      display: 'flex',
      gap: 12,
      justifyContent: 'center',
      alignItems: 'center',
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement("span", null, "pay your bills, earn guaranteed sterling coins."), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-link)',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4
    }
  }, "claim now ", /*#__PURE__*/React.createElement(IconL, {
    name: "arrow-right",
    size: 15
  }))), /*#__PURE__*/React.createElement(Wrap, {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '26px 28px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "S",
    tone: "mint",
    size: 34,
    glow: false
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 26,
      fontWeight: 800,
      letterSpacing: '-0.03em'
    }
  }, "sterling")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 30
    }
  }, /*#__PURE__*/React.createElement("a", {
    style: {
      fontSize: 15,
      fontWeight: 600,
      color: 'var(--text-secondary)'
    },
    href: "#features"
  }, "net worth tracking"), /*#__PURE__*/React.createElement("a", {
    style: {
      fontSize: 15,
      fontWeight: 600,
      color: 'var(--text-secondary)'
    },
    href: "#rewards"
  }, "bill payments"), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm"
  }, "get the app"))));
}

/* ---- hero ---- */
function Hero() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'var(--grad-aura-mint)'
    }
  }), /*#__PURE__*/React.createElement(Wrap, {
    style: {
      position: 'relative',
      textAlign: 'center',
      padding: '90px 28px 40px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "mint",
    style: {
      marginBottom: 24
    }
  }, "your personal CFO"), /*#__PURE__*/React.createElement("h1", {
    style: {
      fontSize: 92,
      fontWeight: 800,
      lineHeight: 0.98,
      letterSpacing: '-0.035em',
      maxWidth: 900
    }
  }, "your money, managed like a boss."), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 22,
      fontWeight: 600,
      color: 'var(--text-secondary)',
      maxWidth: 560,
      margin: '28px 0 34px',
      lineHeight: 1.4
    }
  }, "join 7.5M+ members who track net worth, crush budgets, and win rewards every day."), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "lg",
    iconRight: /*#__PURE__*/React.createElement(IconL, {
      name: "arrow-right",
      size: 18
    })
  }, "download sterling")));
}

/* ---- 3D showcase (fanned cards + coins) ---- */
function Showcase() {
  const cards = [{
    scheme: 'violet',
    x: -320,
    y: 60,
    rot: -18,
    z: 1,
    w: 300
  }, {
    scheme: 'gold',
    x: -150,
    y: 24,
    rot: -9,
    z: 2,
    w: 320
  }, {
    scheme: 'obsidian',
    x: 0,
    y: 0,
    rot: 0,
    z: 3,
    w: 340
  }, {
    scheme: 'emerald',
    x: 160,
    y: 24,
    rot: 9,
    z: 2,
    w: 320
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 520,
      marginTop: 20,
      overflow: 'hidden',
      background: 'radial-gradient(70% 90% at 50% 120%, rgba(34,230,164,0.12), transparent 60%), var(--ink-900)',
      borderTop: '1px solid var(--border-subtle)',
      borderBottom: '1px solid var(--border-subtle)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: 90,
      transform: 'translateX(-50%)',
      width: 0,
      height: 0
    }
  }, cards.map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      position: 'absolute',
      left: c.x,
      top: c.y,
      transform: `rotate(${c.rot}deg)`,
      zIndex: c.z
    }
  }, /*#__PURE__*/React.createElement(CreditCard3D, {
    scheme: c.scheme,
    width: c.w,
    interactive: false,
    holder: "A. LOVELACE",
    last4: ['1188', '7702', '4291', '0043'][i],
    network: i % 2 ? 'mastercard' : 'visa'
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '14%',
      top: 70
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "$",
    tone: "gold",
    size: 70,
    spin: true
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: '15%',
      bottom: 90
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "\u2605",
    tone: "mint",
    size: 54
  })));
}

/* ---- feature section (CRED photo-section style) ---- */
function Feature({
  id,
  eyebrow,
  title,
  sub,
  body,
  cta,
  bg,
  aura,
  art
}) {
  return /*#__PURE__*/React.createElement("div", {
    id: id,
    style: {
      position: 'relative',
      overflow: 'hidden',
      background: bg
    }
  }, aura && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: aura
    }
  }), /*#__PURE__*/React.createElement(Wrap, {
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      gap: 40,
      padding: '110px 28px',
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: '1 1 440px',
      minWidth: 300
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "t-eyebrow",
    style: {
      marginBottom: 18
    }
  }, eyebrow), /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: 60,
      fontWeight: 800,
      lineHeight: 0.98,
      letterSpacing: '-0.03em',
      maxWidth: 560
    }
  }, title), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 24,
      fontWeight: 700,
      margin: '18px 0 0',
      color: 'var(--text-primary)'
    }
  }, sub), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 17,
      fontWeight: 500,
      lineHeight: 1.6,
      color: 'var(--text-secondary)',
      maxWidth: 500,
      margin: '18px 0 32px'
    }
  }, body), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    iconRight: /*#__PURE__*/React.createElement(IconL, {
      name: "arrow-right",
      size: 17
    })
  }, cta)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: '1 1 360px',
      minWidth: 300,
      display: 'flex',
      justifyContent: 'center'
    }
  }, art)));
}

/* ---- ratings ---- */
function Ratings() {
  return /*#__PURE__*/React.createElement(Wrap, {
    style: {
      padding: '96px 28px',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      gap: 48,
      flexWrap: 'wrap',
      marginBottom: 40
    }
  }, [{
    v: '4.8',
    s: 'app store'
  }, {
    v: '4.7',
    s: 'play store'
  }].map((r, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 72,
      fontWeight: 800,
      letterSpacing: '-0.03em',
      fontVariantNumeric: 'tabular-nums'
    }
  }, r.v), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'left'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 3,
      color: 'var(--gold-400)',
      marginBottom: 4
    }
  }, [0, 1, 2, 3, 4].map(k => /*#__PURE__*/React.createElement(IconL, {
    key: k,
    name: "star",
    size: 18,
    color: "var(--gold-400)"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 20,
      fontWeight: 700,
      lineHeight: 1.1,
      color: 'var(--text-secondary)'
    }
  }, r.s.split(' ').map((w, j) => /*#__PURE__*/React.createElement("div", {
    key: j
  }, w))))))), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 26,
      fontWeight: 700,
      maxWidth: 720,
      margin: '0 auto',
      lineHeight: 1.4,
      letterSpacing: '-0.01em'
    }
  }, "\"finally, an app that treats my money with the seriousness it deserves. sterling is smooth, smart, and a little addictive.\""), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 16,
      color: 'var(--text-tertiary)',
      marginTop: 16,
      fontWeight: 600
    }
  }, "\u2014 a very happy member"));
}

/* ---- footer ---- */
function Footer() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)',
      background: 'var(--ink-900)'
    }
  }, /*#__PURE__*/React.createElement(Wrap, {
    style: {
      padding: '80px 28px 40px'
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: 64,
      fontWeight: 800,
      letterSpacing: '-0.03em',
      lineHeight: 1,
      maxWidth: 640
    }
  }, "the good life ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--accent)'
    }
  }, "starts here.")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 30,
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "lg",
    icon: /*#__PURE__*/React.createElement(IconL, {
      name: "apple",
      size: 18
    })
  }, "app store"), /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    size: "lg",
    icon: /*#__PURE__*/React.createElement(IconL, {
      name: "play",
      size: 18
    })
  }, "google play")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 70,
      paddingTop: 28,
      borderTop: '1px solid var(--border-subtle)',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      flexWrap: 'wrap',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Coin, {
    symbol: "S",
    tone: "mint",
    size: 26,
    glow: false
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 18,
      fontWeight: 800
    }
  }, "sterling")), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)',
      fontWeight: 500
    }
  }, "\xA9 2026 sterling money technologies. all rights reserved."))));
}
function Landing() {
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Header, null), /*#__PURE__*/React.createElement(Hero, null), /*#__PURE__*/React.createElement(Showcase, null), /*#__PURE__*/React.createElement(Feature, {
    id: "features",
    eyebrow: "money matters",
    title: "we take your money seriously.",
    sub: "so that you don't have to.",
    body: "track every account in one place, never miss a due date, and see exactly where your money goes \u2014 with reminders, instant settlements, and automatic statement analysis.",
    cta: "experience the upgrade",
    bg: "var(--grad-emerald-card)",
    aura: "var(--grad-aura-mint)",
    art: /*#__PURE__*/React.createElement(CreditCard3D, {
      scheme: "emerald",
      width: 360,
      balance: "$48,210",
      holder: "A. LOVELACE",
      last4: "4291",
      float: true
    })
  }), /*#__PURE__*/React.createElement(Feature, {
    id: "security",
    eyebrow: "airtight",
    title: "security first. and second.",
    sub: "what's yours remains only yours.",
    body: "every transaction and every byte of your data is encrypted end to end. there's no room for mistakes, because we didn't leave any.",
    cta: "become a member",
    bg: "var(--ink-800)",
    art: /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement(Card, {
      variant: "glass",
      padding: 34,
      style: {
        width: 300
      }
    }, /*#__PURE__*/React.createElement(IconL, {
      name: "shield-check",
      size: 64,
      color: "var(--mint-400)",
      style: {
        marginBottom: 18
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 22,
        fontWeight: 800,
        marginBottom: 8
      }
    }, "bank-grade encryption"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 15,
        color: 'var(--text-secondary)',
        lineHeight: 1.5
      }
    }, "256-bit AES \xB7 biometric lock \xB7 zero data selling")))
  }), /*#__PURE__*/React.createElement(Feature, {
    id: "rewards",
    eyebrow: "the good stuff",
    title: "feel special more often.",
    sub: "exclusive rewards for paying your bills.",
    body: "every time you pay a bill on sterling, you earn sterling coins. spend them on curated rewards, experiences, and cashback. on sterling, good begets good.",
    cta: "explore rewards",
    bg: "var(--grad-violet-card)",
    aura: "var(--grad-aura-gold)",
    art: /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 20,
        alignItems: 'center'
      }
    }, /*#__PURE__*/React.createElement(Coin, {
      symbol: "$",
      tone: "gold",
      size: 130,
      spin: true
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 16
      }
    }, /*#__PURE__*/React.createElement(Coin, {
      symbol: "\u2605",
      tone: "mint",
      size: 72
    }), /*#__PURE__*/React.createElement(Coin, {
      symbol: "S",
      tone: "silver",
      size: 56
    })))
  }), /*#__PURE__*/React.createElement(Ratings, null), /*#__PURE__*/React.createElement(Footer, null));
}
ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(Landing, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/site/landing.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.ProgressRing = __ds_scope.ProgressRing;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.StatTile = __ds_scope.StatTile;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.Coin = __ds_scope.Coin;

__ds_ns.CreditCard3D = __ds_scope.CreditCard3D;

})();
