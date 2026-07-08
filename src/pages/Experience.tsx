import { competencies, education, experience } from '../data/resume'
import './Experience.css'

export default function Experience() {
  return (
    <section className="experience">
      <h1 className="page-title">Experience</h1>

      <div className="timeline">
        {experience.map((role) => (
          <article key={`${role.company}-${role.title}-${role.dates}`} className="role">
            <div className="role-header">
              <h2>
                {role.title} <span className="role-company">— {role.company}</span>
              </h2>
              <p className="role-dates">{role.dates}</p>
            </div>
            <p className="role-team">{role.team}</p>
            <ul className="role-highlights">
              {role.highlights.map((h) => (
                <li key={h}>{h}</li>
              ))}
            </ul>
          </article>
        ))}
      </div>

      <h2 className="section-title">Key Competencies</h2>
      <div className="competencies">
        {competencies.map((c) => (
          <div key={c.label} className="competency">
            <p className="competency-label">{c.label}</p>
            <p className="competency-items">{c.items.join(', ')}</p>
          </div>
        ))}
      </div>

      <h2 className="section-title">Education</h2>
      <p className="education">
        {education.degree} — {education.school}
      </p>
    </section>
  )
}
