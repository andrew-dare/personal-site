import { profile } from '../data/resume'
import './Contact.css'

export default function Contact() {
  return (
    <section className="contact">
      <h1 className="page-title">Get in touch</h1>
      <p className="contact-intro">
        Best reached by email — feel free to reach out about roles, projects, or anything
        else.
      </p>

      <div className="contact-list">
        <a className="contact-item" href={`mailto:${profile.email}`}>
          <span className="contact-label">Email</span>
          <span className="contact-value">{profile.email}</span>
        </a>
        <a className="contact-item" href={`tel:${profile.phone}`}>
          <span className="contact-label">Phone</span>
          <span className="contact-value">{profile.phone}</span>
        </a>
        <div className="contact-item">
          <span className="contact-label">Location</span>
          <span className="contact-value">{profile.location}</span>
        </div>
        <a
          className="contact-item"
          href={profile.social.github}
          target="_blank"
          rel="noreferrer"
        >
          <span className="contact-label">GitHub</span>
          <span className="contact-value">github.com/PLACEHOLDER</span>
        </a>
        <a
          className="contact-item"
          href={profile.social.linkedin}
          target="_blank"
          rel="noreferrer"
        >
          <span className="contact-label">LinkedIn</span>
          <span className="contact-value">linkedin.com/in/PLACEHOLDER</span>
        </a>
      </div>
    </section>
  )
}
