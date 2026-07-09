import { useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import ThemeToggle from './ThemeToggle'
import './Layout.css'

const links = [
  { to: '/', label: 'Home', end: true },
  { to: '/experience', label: 'Experience', end: false },
  { to: '/contact', label: 'Contact', end: false },
]

export default function Layout() {
  const [menuOpen, setMenuOpen] = useState(false)
  const location = useLocation()

  useEffect(() => {
    setMenuOpen(false)
  }, [location.pathname])

  useEffect(() => {
    document.body.style.overflow = menuOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [menuOpen])

  return (
    <>
      <header className="site-header">
        <div className="site-header-inner">
          <NavLink to="/" className="brand" end>
            dare<span className="brand-accent">.</span>dev
          </NavLink>

          <nav className="site-nav">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className={({ isActive }) =>
                  isActive ? 'nav-link nav-link-active' : 'nav-link'
                }
              >
                {link.label}
              </NavLink>
            ))}
          </nav>

          <div className="site-header-actions">
            <ThemeToggle />
            <button
              type="button"
              className="menu-toggle"
              aria-label={menuOpen ? 'Close menu' : 'Open menu'}
              aria-expanded={menuOpen}
              aria-controls="mobile-nav"
              onClick={() => setMenuOpen((open) => !open)}
            >
              <span className={menuOpen ? 'menu-icon menu-icon-open' : 'menu-icon'}>
                <span />
                <span />
                <span />
              </span>
            </button>
          </div>
        </div>

        <nav
          id="mobile-nav"
          className={menuOpen ? 'mobile-nav mobile-nav-open' : 'mobile-nav'}
        >
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.end}
              className={({ isActive }) =>
                isActive ? 'mobile-nav-link mobile-nav-link-active' : 'mobile-nav-link'
              }
            >
              {link.label}
            </NavLink>
          ))}
        </nav>
      </header>
      <main className="site-main">
        <Outlet />
      </main>
      <footer className="site-footer">
        <p>© {new Date().getFullYear()} Andrew DaRe</p>
      </footer>
    </>
  )
}
