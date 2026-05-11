// Invoice Ninja v2 — design tokens & shared primitives
// All components consume from this single source of truth.

const IN = {
  // Surfaces — warm off-white system
  bg:        '#F6F4EF',   // canvas background
  surface:   '#FFFFFF',   // cards
  surfaceAlt:'#FBF9F4',   // subtle alt rows / panels
  border:    '#E8E3D8',   // hairlines
  borderStrong: '#D6CFBF',

  // Ink
  ink:       '#1A1814',   // primary text
  ink2:      '#4A4540',   // secondary text
  ink3:      '#857F73',   // tertiary / labels
  ink4:      '#B5AE9F',   // disabled

  // Accent — sharp jade-lime. Modern, distinctive, "approved/paid" vibe.
  accent:    '#1F8A5B',           // primary
  accentInk: '#0E4A30',           // dark
  accentSoft:'#E3F3EA',           // tint
  accentLime:'#A8E22F',           // electric highlight (used sparingly)

  // Sidebar — deep ink
  rail:      '#15140F',
  railInk:   '#E8E5DC',
  railInk2:  '#8A8678',

  // Status
  paid:      '#1F8A5B',
  paidSoft:  '#E3F3EA',
  overdue:   '#C0392B',
  overdueSoft:'#F9E6E2',
  draft:     '#857F73',
  draftSoft: '#EDEAE2',
  sent:      '#B07A1F',
  sentSoft:  '#F6EBD3',
  partial:   '#2A6FDB',
  partialSoft:'#E2ECFB',

  // Type
  sans: '"Geist", "Inter Tight", -apple-system, system-ui, sans-serif',
  mono: '"Geist Mono", "JetBrains Mono", ui-monospace, monospace',

  // Radii
  r1: 6, r2: 10, r3: 14, r4: 20,

  // Shadows
  shadow1: '0 1px 2px rgba(20,18,12,.06)',
  shadow2: '0 4px 16px rgba(20,18,12,.08), 0 1px 2px rgba(20,18,12,.04)',
};

// Mock data --------------------------------------------------------------
const COMPANIES = [
  { id: 'ac', name: 'Acme Studio',     mark: 'AC', tint: '#1F8A5B', unread: 3 },
  { id: 'no', name: 'Northwind Co.',    mark: 'NW', tint: '#2A6FDB', unread: 0 },
  { id: 'lu', name: 'Lumen Architects', mark: 'LU', tint: '#B07A1F', unread: 7 },
  { id: 'hv', name: 'Harbor & Vine',    mark: 'HV', tint: '#7A3FB0', unread: 0 },
  { id: 'kp', name: 'Kestrel Press',    mark: 'KP', tint: '#C0392B', unread: 2 },
  { id: 'ot', name: 'Otter Robotics',   mark: 'OT', tint: '#0E7C8C', unread: 0 },
  { id: 'sv', name: 'Silverleaf Farm',  mark: 'SV', tint: '#3F8B2F', unread: 1 },
  { id: 'mn', name: 'Meridian Health',  mark: 'MN', tint: '#D04A7A', unread: 0 },
  { id: 'bl', name: 'Blackwell Legal',  mark: 'BL', tint: '#4A4540', unread: 0 },
  { id: 'ax', name: 'Axiom Films',      mark: 'AX', tint: '#1F8A5B', unread: 4 },
];

const NAV = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'invoices',  label: 'Invoices', count: 24 },
  { id: 'clients',   label: 'Clients' },
  { id: 'quotes',    label: 'Quotes',   count: 6 },
  { id: 'payments',  label: 'Payments' },
  { id: 'expenses',  label: 'Expenses' },
  { id: 'reports',   label: 'Reports' },
  { id: 'settings',  label: 'Settings' },
];

const INVOICES = [
  { n: 'INV-2041', client: 'Bauhaus Atelier',  amt: 12400.00, due: 'Jun 14',  status: 'overdue', days: 3 },
  { n: 'INV-2040', client: 'North & Co.',      amt:  3850.00, due: 'Jun 22',  status: 'sent' },
  { n: 'INV-2039', client: 'Cobalt Industries',amt: 24750.00, due: 'Jun 28',  status: 'partial', paid: 12000 },
  { n: 'INV-2038', client: 'Pine & Sparrow',   amt:   980.00, due: 'Jun 30',  status: 'sent' },
  { n: 'INV-2037', client: 'Folio Press',      amt:  6400.00, due: 'Jul 02',  status: 'sent' },
  { n: 'INV-2036', client: 'Halcyon Drafting', amt: 18200.00, due: 'May 30',  status: 'paid' },
  { n: 'INV-2035', client: 'Tessera Holdings', amt:  4250.00, due: 'May 28',  status: 'paid' },
  { n: 'INV-2034', client: 'Westwind Coffee',  amt:  1180.00, due: 'May 24',  status: 'draft' },
  { n: 'INV-2033', client: 'Marlow & Sons',    amt:  9600.00, due: 'May 20',  status: 'paid' },
  { n: 'INV-2032', client: 'Quill Studio',     amt:  2400.00, due: 'May 18',  status: 'paid' },
];

const CLIENTS = [
  { name: 'Bauhaus Atelier',  contact: 'Mira Vasquez',  out: 12400.00, ytd:  48200, inv: 8,  city: 'Brooklyn, NY' },
  { name: 'Cobalt Industries',contact: 'Henrik Lund',   out: 12750.00, ytd: 124000, inv: 22, city: 'Copenhagen, DK' },
  { name: 'Folio Press',      contact: 'Jules Park',    out:  6400.00, ytd:  29400, inv: 5,  city: 'Portland, OR' },
  { name: 'Halcyon Drafting', contact: 'Sara Okonkwo',  out:     0.00, ytd:  86200, inv: 14, city: 'Lagos, NG' },
  { name: 'Marlow & Sons',    contact: 'David Marlow',  out:     0.00, ytd:  38000, inv: 6,  city: 'Sydney, AU' },
  { name: 'North & Co.',      contact: 'Tomás Reyes',   out:  3850.00, ytd:  14200, inv: 3,  city: 'Mexico City, MX' },
  { name: 'Pine & Sparrow',   contact: 'Niamh Walsh',   out:   980.00, ytd:   8200, inv: 2,  city: 'Dublin, IE' },
  { name: 'Tessera Holdings', contact: 'A. Schwarzmann',out:     0.00, ytd:  52000, inv: 9,  city: 'Berlin, DE' },
];

// ──────────── Shared primitives ────────────

function Pill({ status, children }) {
  const map = {
    paid:    { bg: IN.paidSoft, fg: IN.paid,    label: 'Paid' },
    overdue: { bg: IN.overdueSoft, fg: IN.overdue, label: 'Overdue' },
    draft:   { bg: IN.draftSoft, fg: IN.draft,   label: 'Draft' },
    sent:    { bg: IN.sentSoft, fg: IN.sent,    label: 'Sent' },
    partial: { bg: IN.partialSoft, fg: IN.partial, label: 'Partial' },
  };
  const s = map[status] || map.sent;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
      padding: '3px 8px', borderRadius: 999, background: s.bg, color: s.fg,
      fontFamily: IN.sans,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: 3, background: s.fg }}></span>
      {children || s.label}
    </span>
  );
}

function Avatar({ mark, tint, size = 28, square = true, ring }) {
  return (
    <div style={{
      width: size, height: size,
      background: tint, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      borderRadius: square ? Math.max(6, size * 0.25) : '50%',
      fontFamily: IN.sans, fontWeight: 600, fontSize: size * 0.4,
      letterSpacing: 0.3,
      boxShadow: ring ? `0 0 0 2px ${IN.rail}, 0 0 0 4px ${IN.accentLime}` : 'none',
      flexShrink: 0,
    }}>{mark}</div>
  );
}

function Btn({ variant = 'primary', size = 'md', children, icon, style }) {
  const sizes = {
    sm: { h: 28, px: 10, fs: 12 },
    md: { h: 34, px: 14, fs: 13 },
    lg: { h: 40, px: 18, fs: 14 },
  }[size];
  const variants = {
    primary: { bg: IN.ink, fg: '#fff', bd: IN.ink },
    accent:  { bg: IN.accent, fg: '#fff', bd: IN.accent },
    ghost:   { bg: 'transparent', fg: IN.ink, bd: IN.border },
    subtle:  { bg: IN.surfaceAlt, fg: IN.ink, bd: IN.border },
  }[variant];
  return (
    <button style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      height: sizes.h, padding: `0 ${sizes.px}px`,
      background: variants.bg, color: variants.fg,
      border: `1px solid ${variants.bd}`,
      borderRadius: IN.r2,
      fontFamily: IN.sans, fontSize: sizes.fs, fontWeight: 500,
      cursor: 'pointer', whiteSpace: 'nowrap',
      ...style,
    }}>
      {icon}{children}
    </button>
  );
}

// Tiny icon set (stroke 1.6, 16×16 unless overridden)
const Ic = {
  search: (s=16) => <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/></svg>,
  plus:   (s=16) => <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M8 3v10M3 8h10"/></svg>,
  chev:   (s=12,dir='down') => <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d={dir==='down'?'M2.5 4.5l3.5 3.5 3.5-3.5':dir==='up'?'M2.5 7.5l3.5-3.5 3.5 3.5':dir==='right'?'M4.5 2.5l3.5 3.5-3.5 3.5':'M7.5 2.5L4 6l3.5 3.5'}/></svg>,
  bell:   (s=16) => <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M3.5 12h9l-1-1.5V7a3.5 3.5 0 1 0-7 0v3.5z"/><path d="M6.5 14a1.5 1.5 0 0 0 3 0"/></svg>,
  menu:   (s=16) => <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M2.5 4h11M2.5 8h11M2.5 12h11"/></svg>,
  filter: (s=14) => <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><path d="M2 3.5h10M3.5 7h7M5 10.5h4"/></svg>,
  more:   (s=16) => <svg width={s} height={s} viewBox="0 0 16 16" fill="currentColor"><circle cx="4" cy="8" r="1.3"/><circle cx="8" cy="8" r="1.3"/><circle cx="12" cy="8" r="1.3"/></svg>,
  arrow:  (s=14,dir='up') => <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d={dir==='up'?'M7 11V3M3.5 6.5L7 3l3.5 3.5':'M7 3v8M3.5 7.5L7 11l3.5-3.5'}/></svg>,
  check:  (s=14) => <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M3 7.5l2.5 2.5L11 4.5"/></svg>,
  // Nav glyphs
  navDash: <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="2.5" y="2.5" width="5" height="6" rx="1"/><rect x="2.5" y="10" width="5" height="3.5" rx="1"/><rect x="8.5" y="2.5" width="5" height="3.5" rx="1"/><rect x="8.5" y="7" width="5" height="6.5" rx="1"/></svg>,
  navInv:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><path d="M3 2h7l3 3v9H3z"/><path d="M10 2v3h3M5.5 8h5M5.5 10.5h5M5.5 5.5h2"/></svg>,
  navCli:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><circle cx="8" cy="6" r="2.5"/><path d="M3 13.5c.5-2.5 2.5-4 5-4s4.5 1.5 5 4"/></svg>,
  navQuo:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><path d="M3 3h10v8l-2.5-1.5H3z"/><path d="M5.5 6.5h5M5.5 8.5h3"/></svg>,
  navPay:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><rect x="2" y="4" width="12" height="8" rx="1.5"/><path d="M2 7h12M5 10h2"/></svg>,
  navExp:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><path d="M8 2v8M4.5 6.5L8 10l3.5-3.5M3 13h10"/></svg>,
  navRep:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"><path d="M2.5 13.5V3M2.5 13.5H14"/><path d="M5 11V8M8 11V5M11 11V7"/></svg>,
  navSet:  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="8" cy="8" r="2"/><path d="M8 1.5v2M8 12.5v2M14.5 8h-2M3.5 8h-2M12.6 3.4l-1.4 1.4M4.8 11.2l-1.4 1.4M12.6 12.6l-1.4-1.4M4.8 4.8L3.4 3.4" strokeLinecap="round"/></svg>,
};

const NAV_ICONS = {
  dashboard: Ic.navDash, invoices: Ic.navInv, clients: Ic.navCli, quotes: Ic.navQuo,
  payments: Ic.navPay, expenses: Ic.navExp, reports: Ic.navRep, settings: Ic.navSet,
};

// Format money (en-US)
const $ = (n, opts={}) => n.toLocaleString('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: opts.cents===false?0:2, maximumFractionDigits: opts.cents===false?0:2 });

// Sparkline (mini bars)
function Spark({ data, w = 120, h = 28, color = IN.accent }) {
  const max = Math.max(...data);
  const bw = w / data.length;
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      {data.map((d, i) => {
        const bh = Math.max(2, (d / max) * h);
        return <rect key={i} x={i*bw+1} y={h-bh} width={bw-2} height={bh} fill={color} opacity={0.25 + 0.75*(d/max)} rx="1"/>;
      })}
    </svg>
  );
}

// Mock background grid (placeholder for chart)
function ChartArea({ w, h, color = IN.accent }) {
  const pts = [10,18,16,22,28,24,32,40,38,46,52,48,58,64,60];
  const max = Math.max(...pts);
  const sw = w/(pts.length-1);
  const poly = pts.map((p,i)=>`${i*sw},${h - (p/max)*(h-12) - 6}`).join(' ');
  const area = `0,${h} ${poly} ${w},${h}`;
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      <defs>
        <linearGradient id="ca-grad" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor={color} stopOpacity="0.25"/>
          <stop offset="1" stopColor={color} stopOpacity="0"/>
        </linearGradient>
      </defs>
      <polygon points={area} fill="url(#ca-grad)"/>
      <polyline points={poly} fill="none" stroke={color} strokeWidth="2" strokeLinejoin="round"/>
    </svg>
  );
}

Object.assign(window, { IN, COMPANIES, NAV, NAV_ICONS, INVOICES, CLIENTS, Pill, Avatar, Btn, Ic, $, Spark, ChartArea });
