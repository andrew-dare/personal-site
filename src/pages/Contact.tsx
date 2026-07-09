import { profile } from '../data/resume'
import { getRouteMeta } from '../data/seo'
import { useSeo } from '../hooks/useSeo'
import './Contact.css'

const meta = getRouteMeta('/contact')

export default function Contact() {
  useSeo(meta.title, meta.description)

  return (
    <section className="contact">
      <h1 className="page-title">Get in touch</h1>
      <p className="contact-intro">
        Best reached on LinkedIn — feel free to reach out about roles, projects, or anything
        else.
      </p>

      <div className="contact-list">
        <a className="contact-item" href={`mailto:${profile.email}`}>
          <span className="contact-label">Email</span>
          <span className="contact-value">{profile.email}</span>
        </a>
        <div className="contact-item">
          <span className="contact-label">Location</span>
          <span className="contact-value">{profile.location}</span>
        </div>
        <a
          className="contact-item"
          href={'https://' + profile.social.github}
          target="_blank"
          rel="noreferrer"
        >
          <span className="contact-label">GitHub</span>
          <span className="contact-value">{profile.social.github}</span>
        </a>
        <a
          className="contact-item"
          href={'https://' + profile.social.linkedin}
          target="_blank"
          rel="noreferrer"
        >
          <span className="contact-label">LinkedIn</span>
          <span className="contact-value">{profile.social.linkedin}</span>
        </a>
      </div>
    </section>
  )
}
