// Invoice Ninja v2 — Navigation chrome and screen content
// Pure presentational. Each screen is parameterized by `current` (company id)
// and (where useful) `nav` (active nav id).

// ──────────────── DESKTOP NAV CHROME ────────────────

/** Persistent company rail (left-most), 64px wide */
function CompanyRail({ current, onPick }) {
  return (
    <div style={{
      width: 64, background: IN.rail, height: '100%',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      padding: '14px 0 14px',
      borderRight: `1px solid ${IN.rail}`,
      flexShrink: 0,
    }}>
      {/* Brand glyph */}
      <div style={{
        width: 36, height: 36, marginBottom: 14,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
          <path d="M4 22 L14 6 L24 22 L19 22 L14 14 L9 22 Z" fill={IN.accentLime}/>
          <circle cx="14" cy="20" r="1.6" fill={IN.rail}/>
        </svg>
      </div>
      <div style={{ width: 32, height: 1, background: 'rgba(255,255,255,.08)', marginBottom: 14 }}/>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, flex: 1, overflow: 'auto' }}>
        {COMPANIES.map((c) => (
          <button key={c.id} onClick={()=>onPick&&onPick(c.id)} title={c.name}
            style={{
              position: 'relative', width: 40, height: 40, padding: 0,
              border: 'none', cursor: 'pointer', background: 'transparent',
              borderRadius: 12,
            }}>
            {/* active indicator */}
            {c.id === current && (
              <div style={{ position:'absolute', left:-14, top: 8, bottom: 8, width: 3, borderRadius: 2, background: IN.accentLime }}/>
            )}
            <Avatar mark={c.mark} tint={c.tint} size={40} square
              ring={c.id === current ? false : false}/>
            {c.id === current && (
              <div style={{position:'absolute', inset:0, borderRadius: 12, boxShadow: `0 0 0 2px ${IN.accentLime}`, pointerEvents:'none'}}/>
            )}
            {c.unread > 0 && c.id !== current && (
              <div style={{
                position: 'absolute', top: -2, right: -2,
                minWidth: 16, height: 16, padding: '0 4px',
                background: IN.overdue, color: '#fff',
                borderRadius: 8, fontSize: 10, fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: IN.sans,
                boxShadow: `0 0 0 2px ${IN.rail}`,
              }}>{c.unread}</div>
            )}
          </button>
        ))}
      </div>

      <button style={{
        width: 40, height: 40, marginTop: 8, padding: 0,
        background: 'transparent', border: `1.5px dashed rgba(255,255,255,.25)`,
        borderRadius: 12, color: 'rgba(255,255,255,.55)', cursor: 'pointer',
      }}>{Ic.plus(16)}</button>

      <div style={{ marginTop: 14 }}>
        <Avatar mark="DS" tint="#4A4540" size={32} square={false}/>
      </div>
    </div>
  );
}

/** Section navigation (Dashboard/Invoices/etc) — desktop sidebar, 232px */
function NavSidebar({ active = 'dashboard', companyName, companyMark, companyTint, withSwitcher, onSwitch }) {
  return (
    <div style={{
      width: 232, background: IN.surface, height: '100%',
      borderRight: `1px solid ${IN.border}`, flexShrink: 0,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Company header */}
      {withSwitcher && (
        <div style={{ padding: '14px 14px 12px', borderBottom: `1px solid ${IN.border}` }}>
          <button onClick={onSwitch} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 10,
            padding: '8px 8px', background: IN.surfaceAlt, border: `1px solid ${IN.border}`,
            borderRadius: IN.r2, cursor: 'pointer', textAlign: 'left',
          }}>
            <Avatar mark={companyMark} tint={companyTint} size={28}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: IN.sans, fontWeight: 600, fontSize: 13, color: IN.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{companyName}</div>
              <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>Switch workspace</div>
            </div>
            <div style={{ color: IN.ink3 }}>{Ic.chev(11)}</div>
          </button>
        </div>
      )}

      <div style={{ padding: '14px 12px', flex: 1 }}>
        <div style={{ fontFamily: IN.sans, fontSize: 10, fontWeight: 600, letterSpacing: 1.2, color: IN.ink3, padding: '0 8px 8px', textTransform: 'uppercase' }}>Workspace</div>
        {NAV.map((n) => {
          const on = n.id === active;
          return (
            <div key={n.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '7px 10px', borderRadius: IN.r2,
              background: on ? IN.accentSoft : 'transparent',
              color: on ? IN.accentInk : IN.ink2,
              fontFamily: IN.sans, fontSize: 13, fontWeight: on ? 600 : 500,
              cursor: 'pointer', marginBottom: 2,
            }}>
              <span style={{ color: on ? IN.accent : IN.ink3, display: 'inline-flex' }}>{NAV_ICONS[n.id]}</span>
              <span style={{ flex: 1 }}>{n.label}</span>
              {n.count != null && (
                <span style={{
                  fontFamily: IN.mono, fontSize: 10, fontWeight: 600,
                  padding: '1px 6px', borderRadius: 999,
                  background: on ? '#fff' : IN.surfaceAlt,
                  color: on ? IN.accent : IN.ink3,
                  border: `1px solid ${IN.border}`,
                }}>{n.count}</span>
              )}
            </div>
          );
        })}

        <div style={{ height: 14 }}/>
        <div style={{ fontFamily: IN.sans, fontSize: 10, fontWeight: 600, letterSpacing: 1.2, color: IN.ink3, padding: '0 8px 8px', textTransform: 'uppercase' }}>Saved</div>
        {['Overdue this week', '> $10k open', 'Top 10 clients'].map((s)=>(
          <div key={s} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '6px 10px', borderRadius: IN.r2,
            color: IN.ink2, fontFamily: IN.sans, fontSize: 12.5,
            cursor: 'pointer',
          }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: IN.borderStrong }}/>
            {s}
          </div>
        ))}
      </div>

      <div style={{ padding: 12, borderTop: `1px solid ${IN.border}` }}>
        <div style={{
          padding: 10, borderRadius: IN.r2, background: IN.surfaceAlt,
          fontFamily: IN.sans, fontSize: 11.5, color: IN.ink2, lineHeight: 1.4,
        }}>
          <div style={{ fontWeight: 600, color: IN.ink, fontSize: 12, marginBottom: 2 }}>Trial · 9 days left</div>
          <div style={{ color: IN.ink3 }}>Upgrade to unlock recurring & multi-currency.</div>
        </div>
      </div>
    </div>
  );
}

/** Top bar present in every screen */
function TopBar({ title, subtitle, breadcrumb, actions, children }) {
  return (
    <div style={{
      height: 56, padding: '0 24px',
      borderBottom: `1px solid ${IN.border}`,
      display: 'flex', alignItems: 'center', gap: 16,
      background: IN.surface,
      flexShrink: 0,
    }}>
      {breadcrumb}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: IN.sans, fontSize: 14, fontWeight: 600, color: IN.ink, letterSpacing: -0.1 }}>{title}</div>
        {subtitle && <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>{subtitle}</div>}
      </div>
      {children}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 6,
        height: 32, padding: '0 12px',
        borderRadius: 8, background: IN.surfaceAlt,
        border: `1px solid ${IN.border}`,
        color: IN.ink3, fontFamily: IN.sans, fontSize: 12.5, width: 220,
      }}>
        {Ic.search(14)} Search clients, invoices, …
        <span style={{ marginLeft: 'auto', fontFamily: IN.mono, fontSize: 10, padding: '1px 5px', background: '#fff', border: `1px solid ${IN.border}`, borderRadius: 4 }}>⌘K</span>
      </div>
      <div style={{ position: 'relative', color: IN.ink2 }}>
        {Ic.bell(18)}
        <span style={{ position: 'absolute', top: -2, right: -2, width: 7, height: 7, borderRadius: 4, background: IN.overdue, boxShadow: `0 0 0 2px ${IN.surface}` }}/>
      </div>
      {actions}
    </div>
  );
}

// ──────────────── SCREEN: DASHBOARD ────────────────

function DashboardScreen({ companyName }) {
  return (
    <div style={{ flex: 1, overflow: 'auto', background: IN.bg }}>
      <TopBar title={companyName} subtitle="Dashboard · May 2026" actions={
        <>
          <Btn variant="ghost" size="sm" icon={Ic.filter(14)}>This month</Btn>
          <Btn variant="accent" size="sm" icon={Ic.plus(14)}>New invoice</Btn>
        </>
      }/>

      <div style={{ padding: 24 }}>
        {/* KPI row */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
          {[
            { label: 'Outstanding',   v: 38420.00,  d: '+12.4%', dir: 'up',   spark: [12,16,11,14,18,22,20,26,24,30] },
            { label: 'Overdue',       v: 12400.00,  d: '1 invoice', dir: null, tone: 'overdue', spark: [4,3,5,2,4,3,2,3,3,3] },
            { label: 'Paid this mo.', v: 84260.00,  d: '+8.2%',  dir: 'up',   tone: 'paid', spark: [22,18,28,24,32,28,36,38,34,42] },
            { label: 'Avg. days to pay', v: 17, money: false,    d: '−3 days',dir: 'down', spark: [22,20,21,18,19,17,18,17,16,17] },
          ].map((k, i) => (
            <div key={i} style={{
              background: IN.surface, border: `1px solid ${IN.border}`,
              borderRadius: IN.r3, padding: 16,
            }}>
              <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3, fontWeight: 500, letterSpacing: 0.2 }}>{k.label}</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
                <div style={{ fontFamily: IN.mono, fontSize: 26, fontWeight: 500, color: IN.ink, letterSpacing: -0.5 }}>
                  {k.money === false ? k.v : $(k.v, { cents: false })}
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
                <span style={{
                  display: 'inline-flex', alignItems: 'center', gap: 3,
                  fontFamily: IN.sans, fontSize: 11.5, fontWeight: 600,
                  color: k.tone === 'overdue' ? IN.overdue : (k.dir === 'down' && k.label.includes('days')) ? IN.paid : (k.dir === 'up' ? IN.paid : IN.ink3),
                }}>
                  {k.dir && Ic.arrow(11, k.dir)}{k.d}
                </span>
                <div style={{ marginLeft: 'auto' }}>
                  <Spark data={k.spark} w={80} h={22} color={k.tone === 'overdue' ? IN.overdue : IN.accent}/>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Chart + activity */}
        <div style={{ display: 'grid', gridTemplateColumns: '1.7fr 1fr', gap: 16, marginBottom: 16 }}>
          <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div>
                <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Revenue</div>
                <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>Last 12 months · paid invoices only</div>
              </div>
              <div style={{ display: 'flex', gap: 4 }}>
                {['12M','6M','3M','1M'].map((t,i)=>(
                  <span key={t} style={{
                    fontFamily: IN.sans, fontSize: 11.5, padding: '4px 10px', borderRadius: 6,
                    background: i===1 ? IN.surfaceAlt : 'transparent',
                    color: i===1 ? IN.ink : IN.ink3, fontWeight: i===1 ? 600 : 500,
                    border: i===1 ? `1px solid ${IN.border}` : '1px solid transparent',
                    cursor: 'pointer',
                  }}>{t}</span>
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 14, marginBottom: 8 }}>
              <div style={{ fontFamily: IN.mono, fontSize: 28, fontWeight: 500, color: IN.ink }}>$684,210</div>
              <div style={{ fontFamily: IN.sans, fontSize: 12, fontWeight: 600, color: IN.paid, display: 'flex', alignItems: 'center', gap: 3 }}>{Ic.arrow(11, 'up')} +18.4% vs prior</div>
            </div>
            <ChartArea w={560} h={140}/>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontFamily: IN.mono, fontSize: 10, color: IN.ink3, letterSpacing: 0.4 }}>
              {['Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar','Apr','May'].map(m=><span key={m}>{m}</span>)}
            </div>
          </div>

          <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Activity</div>
              <span style={{ fontFamily: IN.sans, fontSize: 12, color: IN.ink3, cursor: 'pointer' }}>View all</span>
            </div>
            {[
              { t: 'Bauhaus Atelier paid INV-2036', meta: '$18,200 · 2h ago', d: 'paid' },
              { t: 'Quote QT-118 viewed by Folio Press', meta: '4h ago', d: 'view' },
              { t: 'INV-2041 sent to Bauhaus Atelier', meta: 'yest, 4:12 pm', d: 'sent' },
              { t: 'Expense logged · Adobe CC',  meta: 'yest, 10:30 am · $54.99', d: 'exp' },
              { t: 'Marlow & Sons paid INV-2033', meta: '2 days ago', d: 'paid' },
            ].map((a, i) => (
              <div key={i} style={{ display: 'flex', gap: 10, padding: '10px 0', borderBottom: i===4?'none':`1px solid ${IN.border}` }}>
                <div style={{
                  width: 26, height: 26, borderRadius: 13,
                  background: a.d==='paid'?IN.paidSoft:a.d==='view'?IN.partialSoft:a.d==='sent'?IN.sentSoft:IN.surfaceAlt,
                  color: a.d==='paid'?IN.paid:a.d==='view'?IN.partial:a.d==='sent'?IN.sent:IN.ink3,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor"><circle cx="6" cy="6" r="3"/></svg>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: IN.sans, fontSize: 12.5, color: IN.ink, lineHeight: 1.35 }}>{a.t}</div>
                  <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>{a.meta}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent invoices */}
        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 18px', borderBottom: `1px solid ${IN.border}` }}>
            <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Needs your attention</div>
            <span style={{ fontFamily: IN.sans, fontSize: 12, color: IN.ink3, cursor: 'pointer' }}>All invoices</span>
          </div>
          <InvoiceTable rows={INVOICES.slice(0, 5)} compact/>
        </div>
      </div>
    </div>
  );
}

// ──────────────── SCREEN: INVOICES LIST ────────────────

function InvoicesScreen({ companyName }) {
  return (
    <div style={{ flex: 1, overflow: 'auto', background: IN.bg }}>
      <TopBar title="Invoices" subtitle={`${companyName} · 47 total`} actions={
        <>
          <Btn variant="ghost" size="sm">Export</Btn>
          <Btn variant="accent" size="sm" icon={Ic.plus(14)}>New invoice</Btn>
        </>
      }/>
      <div style={{ padding: 24 }}>
        {/* Filter chips */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 16, alignItems: 'center', flexWrap: 'wrap' }}>
          {[
            { l: 'All',     n: 47, on: true },
            { l: 'Overdue', n: 3,  tone: 'overdue' },
            { l: 'Sent',    n: 14 },
            { l: 'Partial', n: 2 },
            { l: 'Paid',    n: 26 },
            { l: 'Draft',   n: 2 },
          ].map((f) => (
            <span key={f.l} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '6px 12px', borderRadius: 999,
              background: f.on ? IN.ink : IN.surface,
              color: f.on ? '#fff' : (f.tone==='overdue'?IN.overdue:IN.ink2),
              border: `1px solid ${f.on ? IN.ink : IN.border}`,
              fontFamily: IN.sans, fontSize: 12.5, fontWeight: 500, cursor: 'pointer',
            }}>
              {f.l}<span style={{ fontFamily: IN.mono, fontSize: 11, opacity: f.on?0.7:0.6 }}>{f.n}</span>
            </span>
          ))}
          <div style={{ flex: 1 }}/>
          <Btn variant="ghost" size="sm" icon={Ic.filter()}>Filter</Btn>
          <Btn variant="ghost" size="sm">Sort: Newest</Btn>
        </div>

        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, overflow: 'hidden' }}>
          <InvoiceTable rows={INVOICES}/>
        </div>
      </div>
    </div>
  );
}

function InvoiceTable({ rows, compact }) {
  return (
    <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: IN.sans }}>
      <thead>
        <tr style={{ background: IN.surfaceAlt, borderBottom: `1px solid ${IN.border}` }}>
          {['Invoice','Client','Status','Due','Amount',''].map((h,i)=>(
            <th key={h+i} style={{
              textAlign: i===4?'right':'left', padding: '10px 16px',
              fontFamily: IN.sans, fontSize: 10.5, fontWeight: 600, color: IN.ink3,
              letterSpacing: 0.6, textTransform: 'uppercase',
            }}>{h}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((r,i)=>(
          <tr key={r.n} style={{ borderBottom: i===rows.length-1?'none':`1px solid ${IN.border}` }}>
            <td style={{ padding: compact?'10px 16px':'14px 16px', fontFamily: IN.mono, fontSize: 12.5, color: IN.ink, fontWeight: 500 }}>{r.n}</td>
            <td style={{ padding: compact?'10px 16px':'14px 16px', fontFamily: IN.sans, fontSize: 13, color: IN.ink }}>{r.client}</td>
            <td style={{ padding: compact?'10px 16px':'14px 16px' }}><Pill status={r.status}>{r.status==='overdue'&&r.days?`Overdue · ${r.days}d`:undefined}</Pill></td>
            <td style={{ padding: compact?'10px 16px':'14px 16px', fontFamily: IN.sans, fontSize: 12.5, color: r.status==='overdue'?IN.overdue:IN.ink2 }}>{r.due}</td>
            <td style={{ padding: compact?'10px 16px':'14px 16px', textAlign: 'right', fontFamily: IN.mono, fontSize: 13, color: IN.ink, fontWeight: 500 }}>
              {$(r.amt)}
              {r.status==='partial' && (
                <div style={{ fontSize: 10.5, color: IN.partial, fontFamily: IN.mono }}>{$(r.paid)} paid</div>
              )}
            </td>
            <td style={{ padding: compact?'10px 16px':'14px 16px', textAlign: 'right', color: IN.ink3, width: 32 }}>{Ic.more(16)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ──────────────── SCREEN: INVOICE EDITOR ────────────────

function InvoiceEditorScreen({ companyName }) {
  const lines = [
    { d: 'Brand identity · phase 1',    qty: 1,  rate: 4800.00 },
    { d: 'Logo refinement · 3 rounds',  qty: 3,  rate:  650.00 },
    { d: 'Brand guidelines doc',         qty: 1,  rate: 2400.00 },
    { d: 'Working session · Apr 18',     qty: 4,  rate:  185.00 },
  ];
  const sub = lines.reduce((s,l)=>s+l.qty*l.rate, 0);
  const tax = sub * 0.0825;
  const tot = sub + tax;

  return (
    <div style={{ flex: 1, overflow: 'auto', background: IN.bg }}>
      <TopBar
        breadcrumb={
          <div style={{ display:'flex', alignItems:'center', gap: 8, color: IN.ink3, fontFamily: IN.sans, fontSize: 12.5 }}>
            <span style={{ cursor:'pointer' }}>Invoices</span>{Ic.chev(10, 'right')}
            <span style={{ color: IN.ink, fontWeight: 500, fontFamily: IN.mono }}>INV-2042 · Draft</span>
          </div>
        }
        title=""
        actions={
          <>
            <Btn variant="ghost" size="sm">Preview</Btn>
            <Btn variant="subtle" size="sm">Save draft</Btn>
            <Btn variant="accent" size="sm">Send invoice</Btn>
          </>
        }
      />
      <div style={{ padding: '24px', display: 'grid', gridTemplateColumns: '1fr 320px', gap: 24, alignItems: 'start' }}>
        {/* Invoice paper */}
        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 32, boxShadow: IN.shadow1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 28 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <Avatar mark="AC" tint={IN.accent} size={36}/>
                <div>
                  <div style={{ fontFamily: IN.sans, fontWeight: 600, fontSize: 14, color: IN.ink }}>{companyName}</div>
                  <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>14 Spring St · Brooklyn NY 11201</div>
                </div>
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 1, textTransform: 'uppercase', fontWeight: 600 }}>Invoice</div>
              <div style={{ fontFamily: IN.mono, fontSize: 22, fontWeight: 500, color: IN.ink, letterSpacing: -0.4 }}>INV-2042</div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 24, paddingBottom: 24, borderBottom: `1px solid ${IN.border}`, marginBottom: 20 }}>
            <div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6 }}>Bill to</div>
              <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Bauhaus Atelier</div>
              <div style={{ fontFamily: IN.sans, fontSize: 12, color: IN.ink2, marginTop: 2 }}>Mira Vasquez<br/>22 Vandam St · NY 10013</div>
            </div>
            <div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6 }}>Issued</div>
              <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink }}>May 14, 2026</div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6, marginTop: 14 }}>Due</div>
              <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink }}>Jun 13, 2026</div>
            </div>
            <div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6 }}>Terms</div>
              <div style={{ fontFamily: IN.sans, fontSize: 13, color: IN.ink }}>Net 30</div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6, marginTop: 14 }}>PO</div>
              <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink }}>BA-2026-014</div>
            </div>
          </div>

          {/* Line items */}
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 60px 100px 120px', gap: 12, padding: '0 4px 8px', borderBottom: `1px solid ${IN.border}` }}>
              {['Description','Qty','Rate','Amount'].map((h,i)=>(
                <div key={h} style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase', textAlign: i>0?'right':'left' }}>{h}</div>
              ))}
            </div>
            {lines.map((l, i) => (
              <div key={i} style={{ display: 'grid', gridTemplateColumns: '1fr 60px 100px 120px', gap: 12, padding: '12px 4px', borderBottom: `1px solid ${IN.border}` }}>
                <div style={{ fontFamily: IN.sans, fontSize: 13, color: IN.ink }}>{l.d}</div>
                <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink2, textAlign: 'right' }}>{l.qty}</div>
                <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink2, textAlign: 'right' }}>{$(l.rate)}</div>
                <div style={{ fontFamily: IN.mono, fontSize: 13, color: IN.ink, textAlign: 'right', fontWeight: 500 }}>{$(l.qty*l.rate)}</div>
              </div>
            ))}
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '12px 4px', color: IN.ink3, fontFamily: IN.sans, fontSize: 12.5, cursor: 'pointer' }}>
              {Ic.plus(13)} Add line item
            </div>
          </div>

          {/* Totals */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 8 }}>
            <div style={{ width: 280 }}>
              {[
                ['Subtotal', sub], ['Tax (8.25%)', tax],
              ].map(([l, v]) => (
                <div key={l} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 4px', fontFamily: IN.sans, fontSize: 12.5, color: IN.ink2 }}>
                  <span>{l}</span><span style={{ fontFamily: IN.mono }}>{$(v)}</span>
                </div>
              ))}
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 4px', borderTop: `1px solid ${IN.border}`, marginTop: 4 }}>
                <span style={{ fontFamily: IN.sans, fontSize: 13, color: IN.ink, fontWeight: 600 }}>Total due</span>
                <span style={{ fontFamily: IN.mono, fontSize: 18, color: IN.ink, fontWeight: 500 }}>{$(tot)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Side panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <SidePanel title="Settings">
            <SideRow label="Currency" value="USD · $"/>
            <SideRow label="Payment terms" value="Net 30"/>
            <SideRow label="Discount" value="None" muted/>
            <SideRow label="Tax" value="8.25% NY"/>
            <SideRow label="Recurring" value="Off" muted/>
          </SidePanel>
          <SidePanel title="Payment methods">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {[
                { l: 'Stripe — card & ACH', on: true },
                { l: 'PayPal', on: true },
                { l: 'Bank transfer', on: false },
              ].map((m)=>(
                <label key={m.l} style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                  <span style={{
                    width: 28, height: 16, borderRadius: 10,
                    background: m.on ? IN.accent : IN.borderStrong,
                    position: 'relative', flexShrink: 0,
                  }}>
                    <span style={{ position: 'absolute', top: 2, left: m.on?14:2, width: 12, height: 12, borderRadius: 6, background: '#fff' }}/>
                  </span>
                  <span style={{ fontFamily: IN.sans, fontSize: 12.5, color: m.on?IN.ink:IN.ink3 }}>{m.l}</span>
                </label>
              ))}
            </div>
          </SidePanel>
          <SidePanel title="Internal note">
            <div style={{ fontFamily: IN.sans, fontSize: 12, color: IN.ink2, lineHeight: 1.5 }}>
              Bauhaus extended terms to Net 30 starting this PO. Send a reminder if not paid by Jun 20.
            </div>
          </SidePanel>
        </div>
      </div>
    </div>
  );
}

function SidePanel({ title, children }) {
  return (
    <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 16 }}>
      <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 12 }}>{title}</div>
      {children}
    </div>
  );
}
function SideRow({ label, value, muted }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '7px 0', borderBottom: `1px solid ${IN.border}` }}>
      <span style={{ fontFamily: IN.sans, fontSize: 12.5, color: IN.ink3 }}>{label}</span>
      <span style={{ fontFamily: IN.sans, fontSize: 12.5, color: muted?IN.ink3:IN.ink, fontWeight: muted?400:500 }}>{value}</span>
    </div>
  );
}

// ──────────────── SCREEN: CLIENTS ────────────────

function ClientsScreen({ companyName }) {
  return (
    <div style={{ flex: 1, overflow: 'auto', background: IN.bg }}>
      <TopBar title="Clients" subtitle={`${companyName} · 38 active`} actions={
        <>
          <Btn variant="ghost" size="sm">Import</Btn>
          <Btn variant="accent" size="sm" icon={Ic.plus(14)}>Add client</Btn>
        </>
      }/>
      <div style={{ padding: 24 }}>
        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, overflow: 'hidden' }}>
          <div style={{ display: 'flex', padding: '12px 16px', borderBottom: `1px solid ${IN.border}`, alignItems: 'center', gap: 12, background: IN.surfaceAlt }}>
            <div style={{ flex: 1, fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Client</div>
            <div style={{ width: 140, fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Outstanding</div>
            <div style={{ width: 120, fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>YTD billed</div>
            <div style={{ width: 80, fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Invoices</div>
            <div style={{ width: 32 }}/>
          </div>
          {CLIENTS.map((c, i) => (
            <div key={c.name} style={{
              display: 'flex', padding: '14px 16px', alignItems: 'center', gap: 12,
              borderBottom: i===CLIENTS.length-1?'none':`1px solid ${IN.border}`,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1, minWidth: 0 }}>
                <Avatar mark={c.name.split(' ').map(w=>w[0]).slice(0,2).join('')} tint={'#'+(c.name.length*135711).toString(16).slice(-6).padStart(6,'4')} size={32}/>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>{c.name}</div>
                  <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>{c.contact} · {c.city}</div>
                </div>
              </div>
              <div style={{ width: 140, fontFamily: IN.mono, fontSize: 13, color: c.out>0?IN.overdue:IN.ink3, fontWeight: c.out>0?500:400 }}>
                {c.out>0 ? $(c.out) : '—'}
              </div>
              <div style={{ width: 120, fontFamily: IN.mono, fontSize: 13, color: IN.ink }}>{$(c.ytd, { cents: false })}</div>
              <div style={{ width: 80, fontFamily: IN.mono, fontSize: 13, color: IN.ink2 }}>{c.inv}</div>
              <div style={{ width: 32, color: IN.ink3 }}>{Ic.more()}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  CompanyRail, NavSidebar, TopBar, InvoiceTable,
  DashboardScreen, InvoicesScreen, InvoiceEditorScreen, ClientsScreen,
});
