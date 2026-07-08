import { NavLink, Outlet } from 'react-router-dom'
import ThemeToggle from './ThemeToggle'
import './Layout.css'

const links = [
  { to: '/', label: 'Home', end: true },
  { to: '/experience', label: 'Experience', end: false },
  { to: '/contact', label: 'Contact', end: false },
]

export default function Layout() {
  return (
    <>
      <header className="site-header">
        <div className="site-header-inner">
          <NavLink to="/" className="brand" end>
            andrew<span className="brand-accent">.</span>dare
          </NavLink>
          <div className="site-nav-group">
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
            <ThemeToggle />
          </div>
        </div>
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
