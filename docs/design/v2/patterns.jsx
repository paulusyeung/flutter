// Invoice Ninja v2 — Layout patterns (the 3 company-switcher variants)
// Each pattern wraps the same screen content in different chrome.

// ──────────────── PATTERN A: Persistent rail (desktop) ────────────────
function PatternARail({ children }) {
  return (
    <div style={{ display: 'flex', height: '100%', width: '100%', fontFamily: IN.sans, background: IN.bg }}>
      <CompanyRail current="ac"/>
      <NavSidebar active="dashboard" />
      {children}
    </div>
  );
}

// ──────────────── PATTERN B: Top dropdown (desktop) ────────────────
function PatternBDropdown({ children, active = 'dashboard', dropOpen = false }) {
  const cur = COMPANIES[0];
  return (
    <div style={{ display: 'flex', height: '100%', width: '100%', fontFamily: IN.sans, background: IN.bg }}>
      <NavSidebar active={active} withSwitcher companyName={cur.name} companyMark={cur.mark} companyTint={cur.tint}/>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
        {/* Dropdown overlay if shown */}
        {dropOpen && <CompanyDropdownOverlay/>}
        {children}
      </div>
    </div>
  );
}

function CompanyDropdownOverlay() {
  return (
    <div style={{
      position: 'absolute', top: 56+8, left: -210, // anchored to the switcher button in sidebar
      width: 320, background: IN.surface, borderRadius: IN.r3,
      boxShadow: '0 12px 40px rgba(20,18,12,.18), 0 0 0 1px rgba(20,18,12,.06)',
      padding: 8, zIndex: 20, fontFamily: IN.sans,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '6px 10px 10px', borderBottom: `1px solid ${IN.border}`, marginBottom: 6,
      }}>
        <span style={{ color: IN.ink3 }}>{Ic.search(14)}</span>
        <span style={{ fontFamily: IN.sans, fontSize: 12.5, color: IN.ink3 }}>Search workspaces…</span>
      </div>
      <div style={{ maxHeight: 360, overflow: 'auto' }}>
        {COMPANIES.map((c) => (
          <div key={c.id} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '7px 10px', borderRadius: IN.r2,
            background: c.id==='ac'?IN.accentSoft:'transparent',
            cursor: 'pointer',
          }}>
            <Avatar mark={c.mark} tint={c.tint} size={28}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>{c.name}</div>
              <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>
                {c.id==='ac'?'12 open · $38.4k outstanding': c.unread>0?`${c.unread} unread`:'All caught up'}
              </div>
            </div>
            {c.id==='ac' && <span style={{ color: IN.accent }}>{Ic.check()}</span>}
            {c.unread>0 && c.id!=='ac' && (
              <span style={{
                fontFamily: IN.mono, fontSize: 10, fontWeight: 700,
                padding: '2px 6px', borderRadius: 999,
                background: IN.overdueSoft, color: IN.overdue,
              }}>{c.unread}</span>
            )}
          </div>
        ))}
      </div>
      <div style={{ borderTop: `1px solid ${IN.border}`, marginTop: 6, paddingTop: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px', borderRadius: IN.r2, color: IN.ink2, fontSize: 12.5, fontFamily: IN.sans, cursor: 'pointer' }}>
          {Ic.plus(14)} New workspace
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px', borderRadius: IN.r2, color: IN.ink2, fontSize: 12.5, fontFamily: IN.sans, cursor: 'pointer' }}>
          <span style={{ display: 'inline-flex', width: 14, height: 14, alignItems: 'center', justifyContent: 'center', color: IN.ink3 }}>⌥</span>
          Manage workspaces
        </div>
      </div>
    </div>
  );
}

// ──────────────── PATTERN C: Hub (desktop) ────────────────
// Dedicated home screen showing all companies as cards.
function PatternCHub() {
  return (
    <div style={{ display: 'flex', height: '100%', width: '100%', fontFamily: IN.sans, background: IN.bg }}>
      {/* Slim left rail with just brand + profile (no companies) */}
      <div style={{
        width: 56, background: IN.rail, height: '100%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        padding: '14px 0', flexShrink: 0,
      }}>
        <div style={{ marginBottom: 'auto' }}>
          <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
            <path d="M4 22 L14 6 L24 22 L19 22 L14 14 L9 22 Z" fill={IN.accentLime}/>
            <circle cx="14" cy="20" r="1.6" fill={IN.rail}/>
          </svg>
        </div>
        <Avatar mark="DS" tint="#4A4540" size={32} square={false}/>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <div style={{
          height: 56, padding: '0 32px',
          borderBottom: `1px solid ${IN.border}`,
          display: 'flex', alignItems: 'center', gap: 16,
          background: IN.surface,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: IN.sans, fontSize: 14, fontWeight: 600, color: IN.ink, letterSpacing: -0.1 }}>Workspaces</div>
            <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>Daria Solomon · 10 workspaces</div>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            height: 32, padding: '0 12px',
            borderRadius: 8, background: IN.surfaceAlt,
            border: `1px solid ${IN.border}`,
            color: IN.ink3, fontFamily: IN.sans, fontSize: 12.5, width: 240,
          }}>{Ic.search(14)} Search workspaces, invoices…</div>
          <Btn variant="ghost" size="sm">Import</Btn>
          <Btn variant="accent" size="sm" icon={Ic.plus(14)}>New workspace</Btn>
        </div>

        <div style={{ padding: '24px 32px' }}>
          {/* Aggregate strip across all 10 */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
            {[
              ['Across all workspaces', '$284,160 outstanding'],
              ['Overdue', '6 invoices · $42.8k', 'overdue'],
              ['Paid past 30d', '$612,440'],
              ['Quotes pending', '11 · $94.2k'],
            ].map(([l, v, t], i) => (
              <div key={i} style={{
                background: IN.surface, border: `1px solid ${IN.border}`,
                borderRadius: IN.r3, padding: '14px 16px',
              }}>
                <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.3, fontWeight: 500 }}>{l}</div>
                <div style={{ fontFamily: IN.mono, fontSize: 18, fontWeight: 500, color: t==='overdue'?IN.overdue:IN.ink, marginTop: 4, letterSpacing: -0.3 }}>{v}</div>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
            <h2 style={{ margin: 0, fontFamily: IN.sans, fontSize: 18, fontWeight: 600, color: IN.ink, letterSpacing: -0.3 }}>Your workspaces</h2>
            <div style={{ display: 'flex', gap: 4, color: IN.ink3, fontSize: 12, fontFamily: IN.sans }}>
              <span style={{ padding: '4px 8px', borderRadius: 6, background: IN.surface, border: `1px solid ${IN.border}`, color: IN.ink, fontWeight: 500 }}>Grid</span>
              <span style={{ padding: '4px 8px' }}>List</span>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
            {COMPANIES.map((c, i) => {
              const stats = [
                { o: 38420, p: 84260, ov: 1 },
                { o: 4180,  p: 22400, ov: 0 },
                { o: 28200, p: 142800, ov: 2 },
                { o: 6400,  p: 18000, ov: 0 },
                { o: 12400, p: 28200, ov: 1 },
                { o: 0,     p: 38400, ov: 0 },
                { o: 2200,  p: 12800, ov: 0 },
                { o: 14800, p: 92400, ov: 0 },
                { o: 0,     p: 64800, ov: 0 },
                { o: 28800, p: 86400, ov: 2 },
              ][i];
              return (
                <div key={c.id} style={{
                  background: IN.surface, border: `1px solid ${IN.border}`,
                  borderRadius: IN.r3, padding: 16,
                  cursor: 'pointer',
                }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 14 }}>
                    <Avatar mark={c.mark} tint={c.tint} size={40}/>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontFamily: IN.sans, fontWeight: 600, fontSize: 14, color: IN.ink }}>{c.name}</div>
                      <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>
                        {i===0?'Owner':i<3?'Admin':'Member'} · {12+i*3} clients
                      </div>
                    </div>
                    {stats.ov > 0 && <Pill status="overdue">{stats.ov} overdue</Pill>}
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, fontFamily: IN.sans }}>
                    <div>
                      <div style={{ fontSize: 10.5, color: IN.ink3, letterSpacing: 0.5, textTransform: 'uppercase', fontWeight: 600 }}>Outstanding</div>
                      <div style={{ fontFamily: IN.mono, fontSize: 15, color: stats.o>0?IN.ink:IN.ink3, fontWeight: 500, marginTop: 2 }}>{stats.o>0?$(stats.o,{cents:false}):'—'}</div>
                    </div>
                    <div>
                      <div style={{ fontSize: 10.5, color: IN.ink3, letterSpacing: 0.5, textTransform: 'uppercase', fontWeight: 600 }}>Paid 30d</div>
                      <div style={{ fontFamily: IN.mono, fontSize: 15, color: IN.ink, fontWeight: 500, marginTop: 2 }}>{$(stats.p,{cents:false})}</div>
                    </div>
                  </div>
                </div>
              );
            })}
            {/* New workspace card */}
            <div style={{
              background: 'transparent', border: `1.5px dashed ${IN.borderStrong}`,
              borderRadius: IN.r3, padding: 16, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center', minHeight: 132,
              color: IN.ink3, cursor: 'pointer',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 18, background: IN.surface,
                border: `1px solid ${IN.border}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 8,
              }}>{Ic.plus(16)}</div>
              <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 500 }}>New workspace</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ──────────────── MOBILE patterns ────────────────

// Pattern A mobile — horizontal company strip + bottom tab bar
function PatternAMobile() {
  return (
    <div style={{ width: '100%', height: '100%', background: IN.bg, display: 'flex', flexDirection: 'column', fontFamily: IN.sans, overflow: 'hidden' }}>
      <StatusBar/>
      {/* Company strip */}
      <div style={{ background: IN.rail, padding: '8px 12px 10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
            <svg width="22" height="22" viewBox="0 0 28 28" fill="none"><path d="M4 22 L14 6 L24 22 L19 22 L14 14 L9 22 Z" fill={IN.accentLime}/><circle cx="14" cy="20" r="1.6" fill={IN.rail}/></svg>
            <span style={{ color: IN.railInk, fontFamily: IN.sans, fontSize: 13, fontWeight: 600 }}>Invoice Ninja</span>
          </div>
          <div style={{ color: IN.railInk2 }}>{Ic.bell(18)}</div>
          <Avatar mark="DS" tint="#4A4540" size={26} square={false}/>
        </div>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 2 }}>
          {COMPANIES.slice(0,8).map((c, i) => (
            <div key={c.id} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              flexShrink: 0, width: 52, position: 'relative',
            }}>
              <div style={{ position: 'relative' }}>
                <Avatar mark={c.mark} tint={c.tint} size={40} square/>
                {c.id==='ac' && (
                  <div style={{ position:'absolute', inset:-3, borderRadius: 14, boxShadow: `inset 0 0 0 2px ${IN.accentLime}`, pointerEvents:'none' }}/>
                )}
                {c.unread > 0 && c.id !== 'ac' && (
                  <div style={{ position:'absolute', top: -3, right: -3, minWidth: 16, height: 16, padding: '0 4px', background: IN.overdue, color: '#fff', borderRadius: 8, fontSize: 10, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 0 0 2px ${IN.rail}` }}>{c.unread}</div>
                )}
              </div>
              <div style={{ fontFamily: IN.sans, fontSize: 10, color: c.id==='ac'?IN.accentLime:IN.railInk2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 52, fontWeight: c.id==='ac'?600:500 }}>{c.name.split(' ')[0]}</div>
            </div>
          ))}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0, width: 52 }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'transparent', border: `1.5px dashed rgba(255,255,255,.2)`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: IN.railInk2 }}>{Ic.plus(16)}</div>
          </div>
        </div>
      </div>
      <MobileDashboardBody/>
      <MobileTabBar active="dashboard"/>
    </div>
  );
}

// Pattern B mobile — top dropdown
function PatternBMobile({ dropOpen = false }) {
  const cur = COMPANIES[0];
  return (
    <div style={{ width: '100%', height: '100%', background: IN.bg, display: 'flex', flexDirection: 'column', fontFamily: IN.sans, overflow: 'hidden', position: 'relative' }}>
      <StatusBar/>
      <div style={{ background: IN.surface, padding: '10px 14px', borderBottom: `1px solid ${IN.border}`, display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 1, padding: '4px 8px 4px 4px', background: IN.surfaceAlt, border: `1px solid ${IN.border}`, borderRadius: 10 }}>
          <Avatar mark={cur.mark} tint={cur.tint} size={28}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>{cur.name}</div>
            <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3 }}>Tap to switch · 10 workspaces</div>
          </div>
          <span style={{ color: IN.ink3 }}>{Ic.chev(11)}</span>
        </div>
        <div style={{ color: IN.ink2 }}>{Ic.bell(18)}</div>
      </div>
      <MobileDashboardBody/>
      <MobileTabBar active="dashboard"/>

      {dropOpen && (
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(20,18,12,.4)', backdropFilter: 'blur(2px)', zIndex: 20 }}>
          <div style={{
            position: 'absolute', top: 92, left: 12, right: 12,
            background: IN.surface, borderRadius: 14,
            boxShadow: '0 20px 60px rgba(0,0,0,.25)', padding: 6,
          }}>
            <div style={{ padding: 8, fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Switch workspace</div>
            {COMPANIES.slice(0, 6).map((c) => (
              <div key={c.id} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                padding: '8px 10px', borderRadius: 10,
                background: c.id==='ac'?IN.accentSoft:'transparent',
              }}>
                <Avatar mark={c.mark} tint={c.tint} size={28}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>{c.name}</div>
                  <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>{c.unread>0?`${c.unread} unread`:'All caught up'}</div>
                </div>
                {c.id==='ac' && <span style={{ color: IN.accent }}>{Ic.check()}</span>}
              </div>
            ))}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px', borderTop: `1px solid ${IN.border}`, marginTop: 4, color: IN.ink2, fontFamily: IN.sans, fontSize: 13 }}>
              {Ic.plus(14)} New workspace
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Pattern C mobile — hub home screen
function PatternCMobile() {
  return (
    <div style={{ width: '100%', height: '100%', background: IN.bg, display: 'flex', flexDirection: 'column', fontFamily: IN.sans, overflow: 'hidden' }}>
      <StatusBar/>
      <div style={{ padding: '14px 16px 10px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>Good afternoon, Daria</div>
          <div style={{ fontFamily: IN.sans, fontSize: 20, fontWeight: 600, color: IN.ink, letterSpacing: -0.3 }}>Workspaces</div>
        </div>
        <Avatar mark="DS" tint="#4A4540" size={34} square={false}/>
      </div>

      {/* Aggregate */}
      <div style={{ margin: '0 16px 12px', background: IN.rail, color: IN.railInk, borderRadius: IN.r3, padding: 14 }}>
        <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.railInk2, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Across all workspaces</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 4 }}>
          <div style={{ fontFamily: IN.mono, fontSize: 22, fontWeight: 500, color: '#fff', letterSpacing: -0.4 }}>$284,160</div>
          <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.accentLime, fontWeight: 600 }}>outstanding</div>
        </div>
        <div style={{ display: 'flex', gap: 14, marginTop: 10, fontFamily: IN.sans, fontSize: 11.5, color: IN.railInk2 }}>
          <span><span style={{ color: IN.overdue, fontWeight: 600 }}>6</span> overdue</span>
          <span><span style={{ color: '#fff', fontWeight: 600 }}>$612k</span> paid 30d</span>
          <span><span style={{ color: '#fff', fontWeight: 600 }}>11</span> quotes</span>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 12px' }}>
        {COMPANIES.slice(0, 6).map((c, i) => {
          const out = [38420, 4180, 28200, 6400, 12400, 0][i];
          const ov = [1, 0, 2, 0, 1, 0][i];
          return (
            <div key={c.id} style={{
              background: IN.surface, border: `1px solid ${IN.border}`,
              borderRadius: IN.r3, padding: 14, marginBottom: 10,
              display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <Avatar mark={c.mark} tint={c.tint} size={42}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: IN.sans, fontSize: 14, fontWeight: 600, color: IN.ink }}>{c.name}</div>
                <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3, marginTop: 2 }}>
                  {out>0 ? <><span style={{ fontFamily: IN.mono, color: ov>0?IN.overdue:IN.ink2, fontWeight: 600 }}>{$(out,{cents:false})}</span> outstanding</> : 'All caught up'}
                </div>
              </div>
              {ov>0 && <Pill status="overdue">{ov}</Pill>}
              <span style={{ color: IN.ink3 }}>{Ic.chev(11, 'right')}</span>
            </div>
          );
        })}
        <div style={{
          border: `1.5px dashed ${IN.borderStrong}`, borderRadius: IN.r3,
          padding: 14, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          color: IN.ink3, fontFamily: IN.sans, fontSize: 13, fontWeight: 500,
        }}>{Ic.plus(14)} New workspace</div>
      </div>
    </div>
  );
}

// Mobile dashboard body (re-used by patterns A and B)
function MobileDashboardBody() {
  return (
    <div style={{ flex: 1, overflow: 'auto', padding: '14px 14px 14px' }}>
      <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600, marginBottom: 8 }}>Acme Studio · Dashboard</div>

      {/* Hero KPI */}
      <div style={{ background: IN.ink, color: '#fff', borderRadius: IN.r3, padding: 16, marginBottom: 10 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ fontFamily: IN.sans, fontSize: 11, color: 'rgba(255,255,255,.55)', fontWeight: 500, letterSpacing: 0.3 }}>Outstanding</div>
            <div style={{ fontFamily: IN.mono, fontSize: 30, fontWeight: 500, letterSpacing: -0.5, marginTop: 4 }}>$38,420</div>
            <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.accentLime, fontWeight: 600, marginTop: 4, display: 'inline-flex', alignItems: 'center', gap: 3 }}>{Ic.arrow(11,'up')} +12.4% this month</div>
          </div>
          <Spark data={[12,16,11,14,18,22,20,26,24,30]} w={80} h={40} color={IN.accentLime}/>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
          <div style={{ flex: 1, padding: '8px 10px', borderRadius: 10, background: 'rgba(255,255,255,.08)' }}>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,.55)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>Overdue</div>
            <div style={{ fontFamily: IN.mono, fontSize: 13, color: '#fff', fontWeight: 500, marginTop: 2 }}>$12,400 · 1</div>
          </div>
          <div style={{ flex: 1, padding: '8px 10px', borderRadius: 10, background: 'rgba(255,255,255,.08)' }}>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,.55)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>Paid 30d</div>
            <div style={{ fontFamily: IN.mono, fontSize: 13, color: '#fff', fontWeight: 500, marginTop: 2 }}>$84,260</div>
          </div>
        </div>
      </div>

      {/* Quick actions */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8, marginBottom: 14 }}>
        {[
          ['New invoice', Ic.plus(15)],
          ['Add client', Ic.navCli],
          ['Log expense', Ic.navExp],
          ['Reports', Ic.navRep],
        ].map(([l, ic], i) => (
          <div key={l} style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r2, padding: '10px 6px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, color: IN.ink2 }}>
            <div style={{ color: i===0?IN.accent:IN.ink2 }}>{ic}</div>
            <div style={{ fontFamily: IN.sans, fontSize: 10.5, fontWeight: 500, color: IN.ink, textAlign: 'center', lineHeight: 1.2 }}>{l}</div>
          </div>
        ))}
      </div>

      {/* Needs attention */}
      <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, overflow: 'hidden' }}>
        <div style={{ padding: '12px 14px', borderBottom: `1px solid ${IN.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Needs attention</div>
          <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>3 items</div>
        </div>
        {INVOICES.filter(i=>i.status!=='paid'&&i.status!=='draft').slice(0,3).map((r, i, arr) => (
          <div key={r.n} style={{ padding: '12px 14px', borderBottom: i===arr.length-1?'none':`1px solid ${IN.border}`, display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontFamily: IN.mono, fontSize: 11.5, color: IN.ink3 }}>{r.n}</span>
                <Pill status={r.status}>{r.status==='overdue'?`Overdue ${r.days}d`:undefined}</Pill>
              </div>
              <div style={{ fontFamily: IN.sans, fontSize: 13, color: IN.ink, fontWeight: 500, marginTop: 3 }}>{r.client}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: IN.mono, fontSize: 13.5, color: IN.ink, fontWeight: 500 }}>{$(r.amt)}</div>
              <div style={{ fontFamily: IN.sans, fontSize: 10.5, color: IN.ink3 }}>due {r.due}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function MobileTabBar({ active }) {
  const tabs = [
    { id: 'dashboard', l: 'Home',     ic: Ic.navDash },
    { id: 'invoices',  l: 'Invoices', ic: Ic.navInv },
    { id: 'new',       l: '',         ic: null },
    { id: 'clients',   l: 'Clients',  ic: Ic.navCli },
    { id: 'more',      l: 'More',     ic: Ic.menu(16) },
  ];
  return (
    <div style={{
      borderTop: `1px solid ${IN.border}`, background: IN.surface,
      padding: '6px 8px 14px',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'space-around',
    }}>
      {tabs.map((t) => {
        if (t.id === 'new') return (
          <div key="n" style={{ position: 'relative', width: 52, display: 'flex', justifyContent: 'center' }}>
            <button style={{
              width: 46, height: 46, borderRadius: 23, border: 'none',
              background: IN.accent, color: '#fff', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 6px 16px rgba(31,138,91,.35)', marginTop: -12,
            }}>{Ic.plus(20)}</button>
          </div>
        );
        const on = t.id === active;
        return (
          <div key={t.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: on ? IN.ink : IN.ink3, padding: '6px 8px', minWidth: 52,
          }}>
            <span style={{ color: on ? IN.accent : IN.ink3 }}>{t.ic}</span>
            <span style={{ fontFamily: IN.sans, fontSize: 10, fontWeight: on?600:500 }}>{t.l}</span>
          </div>
        );
      })}
    </div>
  );
}

function StatusBar() {
  return (
    <div style={{
      height: 32, padding: '0 18px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      fontFamily: IN.sans, fontSize: 12, fontWeight: 600, color: IN.ink,
      background: 'transparent', flexShrink: 0,
    }}>
      <span>9:41</span>
      <span style={{ display: 'inline-flex', gap: 5, alignItems: 'center' }}>
        <svg width="14" height="10" viewBox="0 0 14 10" fill="none"><circle cx="2" cy="8" r="1" fill="currentColor"/><circle cx="6" cy="8" r="1" fill="currentColor"/><rect x="9" y="5" width="2" height="4" fill="currentColor"/><rect x="12" y="2" width="2" height="7" fill="currentColor"/></svg>
        <svg width="14" height="10" viewBox="0 0 14 10" fill="none" stroke="currentColor" strokeWidth="1"><path d="M2 6c1.5-1.5 3-2.5 5-2.5s3.5 1 5 2.5"/><path d="M4 7.5c1-1 2-1.5 3-1.5s2 .5 3 1.5"/><circle cx="7" cy="9" r="0.8" fill="currentColor"/></svg>
        <svg width="20" height="10" viewBox="0 0 20 10" fill="none"><rect x="0.5" y="1" width="16" height="8" rx="2" stroke="currentColor"/><rect x="2" y="2.5" width="11" height="5" rx="1" fill="currentColor"/><rect x="17" y="3.5" width="1.5" height="3" fill="currentColor"/></svg>
      </span>
    </div>
  );
}

// Mobile invoice list
function MobileInvoicesScreen({ companyName }) {
  return (
    <div style={{ width: '100%', height: '100%', background: IN.bg, display: 'flex', flexDirection: 'column', fontFamily: IN.sans, overflow: 'hidden' }}>
      <StatusBar/>
      <div style={{ padding: '6px 16px 12px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <span style={{ color: IN.ink2, padding: 4, marginLeft: -4 }}>{Ic.chev(14, 'left')}</span>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: IN.sans, fontSize: 18, fontWeight: 600, color: IN.ink, letterSpacing: -0.2 }}>Invoices</div>
          <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>{companyName} · 47 total</div>
        </div>
        <span style={{ color: IN.ink2 }}>{Ic.search(18)}</span>
      </div>
      <div style={{ padding: '0 16px 12px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        {[
          { l: 'All', n: 47, on: true },
          { l: 'Overdue', n: 3, tone: 'overdue' },
          { l: 'Sent', n: 14 }, { l: 'Paid', n: 26 }, { l: 'Draft', n: 2 },
        ].map((f) => (
          <span key={f.l} style={{
            flexShrink: 0,
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '6px 12px', borderRadius: 999,
            background: f.on ? IN.ink : IN.surface, color: f.on ? '#fff' : (f.tone==='overdue'?IN.overdue:IN.ink2),
            border: `1px solid ${f.on?IN.ink:IN.border}`, fontFamily: IN.sans, fontSize: 12, fontWeight: 500,
          }}>{f.l}<span style={{ fontFamily: IN.mono, fontSize: 10.5, opacity: 0.7 }}>{f.n}</span></span>
        ))}
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 14px' }}>
        {INVOICES.slice(0, 7).map((r) => (
          <div key={r.n} style={{
            background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3,
            padding: 14, marginBottom: 8,
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontFamily: IN.mono, fontSize: 11.5, color: IN.ink3 }}>{r.n}</span>
                  <Pill status={r.status}>{r.status==='overdue'?`Overdue ${r.days}d`:undefined}</Pill>
                </div>
                <div style={{ fontFamily: IN.sans, fontSize: 14, fontWeight: 600, color: IN.ink, marginTop: 4 }}>{r.client}</div>
                <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>due {r.due}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: IN.mono, fontSize: 15, color: IN.ink, fontWeight: 500 }}>{$(r.amt)}</div>
                {r.status==='partial' && <div style={{ fontFamily: IN.mono, fontSize: 10.5, color: IN.partial }}>{$(r.paid)} paid</div>}
              </div>
            </div>
          </div>
        ))}
      </div>
      <MobileTabBar active="invoices"/>
    </div>
  );
}

// Mobile invoice editor (preview-style)
function MobileEditorScreen() {
  const lines = [
    { d: 'Brand identity · phase 1',    qty: 1,  rate: 4800.00 },
    { d: 'Logo refinement · 3 rounds',  qty: 3,  rate:  650.00 },
    { d: 'Brand guidelines doc',         qty: 1,  rate: 2400.00 },
  ];
  const sub = lines.reduce((s,l)=>s+l.qty*l.rate, 0);
  return (
    <div style={{ width: '100%', height: '100%', background: IN.bg, display: 'flex', flexDirection: 'column', fontFamily: IN.sans, overflow: 'hidden' }}>
      <StatusBar/>
      <div style={{ padding: '6px 16px 10px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <span style={{ color: IN.ink2, padding: 4, marginLeft: -4 }}>{Ic.chev(14, 'left')}</span>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: IN.mono, fontSize: 14, fontWeight: 500, color: IN.ink }}>INV-2042</div>
          <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>Draft · Bauhaus Atelier</div>
        </div>
        <span style={{ color: IN.ink2 }}>{Ic.more()}</span>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '0 14px 14px' }}>
        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 16, marginBottom: 10 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.5, fontWeight: 600, textTransform: 'uppercase' }}>Total due</div>
            <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3 }}>Jun 13</div>
          </div>
          <div style={{ fontFamily: IN.mono, fontSize: 30, fontWeight: 500, color: IN.ink, letterSpacing: -0.6, marginTop: 4 }}>{$(sub*1.0825)}</div>
        </div>

        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 14, marginBottom: 10 }}>
          <div style={{ fontFamily: IN.sans, fontSize: 11, color: IN.ink3, letterSpacing: 0.5, fontWeight: 600, textTransform: 'uppercase', marginBottom: 10 }}>Bill to</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Avatar mark="BA" tint="#7A3FB0" size={36}/>
            <div>
              <div style={{ fontFamily: IN.sans, fontSize: 13.5, fontWeight: 600, color: IN.ink }}>Bauhaus Atelier</div>
              <div style={{ fontFamily: IN.sans, fontSize: 11.5, color: IN.ink3 }}>Mira Vasquez · NY</div>
            </div>
          </div>
        </div>

        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, overflow: 'hidden', marginBottom: 10 }}>
          <div style={{ padding: '12px 14px', borderBottom: `1px solid ${IN.border}`, display: 'flex', justifyContent: 'space-between' }}>
            <div style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Line items</div>
            <span style={{ fontFamily: IN.sans, fontSize: 12, color: IN.accent, fontWeight: 500 }}>+ Add</span>
          </div>
          {lines.map((l, i, arr) => (
            <div key={i} style={{ padding: '12px 14px', borderBottom: i===arr.length-1?'none':`1px solid ${IN.border}`, display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: IN.sans, fontSize: 13, color: IN.ink }}>{l.d}</div>
                <div style={{ fontFamily: IN.mono, fontSize: 11, color: IN.ink3, marginTop: 2 }}>{l.qty} × {$(l.rate)}</div>
              </div>
              <div style={{ fontFamily: IN.mono, fontSize: 13.5, color: IN.ink, fontWeight: 500 }}>{$(l.qty*l.rate)}</div>
            </div>
          ))}
        </div>

        <div style={{ background: IN.surface, border: `1px solid ${IN.border}`, borderRadius: IN.r3, padding: 14 }}>
          <SideRow label="Subtotal" value={$(sub)}/>
          <SideRow label="Tax (8.25%)" value={$(sub*0.0825)}/>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 10 }}>
            <span style={{ fontFamily: IN.sans, fontSize: 13, fontWeight: 600, color: IN.ink }}>Total</span>
            <span style={{ fontFamily: IN.mono, fontSize: 18, fontWeight: 500, color: IN.ink }}>{$(sub*1.0825)}</span>
          </div>
        </div>
      </div>
      <div style={{ padding: '8px 14px 14px', borderTop: `1px solid ${IN.border}`, background: IN.surface, display: 'flex', gap: 8 }}>
        <Btn variant="subtle" size="lg" style={{ flex: 1, justifyContent: 'center' }}>Preview</Btn>
        <Btn variant="accent" size="lg" style={{ flex: 1.4, justifyContent: 'center' }}>Send invoice</Btn>
      </div>
    </div>
  );
}

Object.assign(window, {
  PatternARail, PatternBDropdown, PatternCHub,
  PatternAMobile, PatternBMobile, PatternCMobile,
  MobileInvoicesScreen, MobileEditorScreen,
});
