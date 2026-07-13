import { Link } from 'react-router-dom'
import { profile } from '../data/resume'
import { getRouteMeta } from '../data/seo'
import { useSeo } from '../hooks/useSeo'
import './Home.css'

const meta = getRouteMeta('/')

export default function Home() {
  useSeo(meta.title, meta.description)

  return (
    <section className="home">
      <p className="eyebrow">Hi, I'm</p>
      <h1 className="home-title">{profile.name}</h1>
      <p className="home-role">{profile.title} · {profile.location}</p>
      <div className="home-summary">
        {profile.summary.map((paragraph) => (
          <p key={paragraph}>{paragraph}</p>
        ))}
      </div>
      <div className="home-actions">
        <Link to="/experience" className="btn btn-primary">
          See my experience
        </Link>
        <Link to="/contact" className="btn btn-secondary">
          Get in touch
        </Link>
      </div>
    </section>
  )
}
