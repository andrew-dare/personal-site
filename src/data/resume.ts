export const profile = {
  name: 'Andrew DaRe',
  title: 'Software Engineer',
  location: 'Los Angeles, CA',
  phone: '760-840-0191',
  email: 'andrew@dare.dev',
  site: 'www.dare.dev',
  summary:
    "Full-stack software engineer with nearly a decade of experience shipping customer-facing billing, growth, and real-time features at Dropbox and Atlassian. Strong in TypeScript, Node.js, and React, and skilled at translating complex engineering problems into language technical and non-technical stakeholders can act on.",
  // Placeholder — not in resume, update with real profiles.
  social: {
    github: 'https://github.com/PLACEHOLDER',
    linkedin: 'https://linkedin.com/in/PLACEHOLDER',
  },
}

export const competencies = [
  { label: 'Languages', items: ['TypeScript', 'JavaScript', 'Python', 'PHP'] },
  { label: 'Frontend', items: ['React', 'HTML/CSS'] },
  {
    label: 'Backend & Data',
    items: [
      'Node.js',
      'GraphQL APIs',
      'REST APIs',
      'MySQL/PostgreSQL',
      'MongoDB',
      'Redis',
    ],
  },
  {
    label: 'Infrastructure & Tooling',
    items: ['Docker', 'Terraform', 'AWS', 'CI/CD pipelines'],
  },
  {
    label: 'AI-assisted development',
    items: ['Claude Code', 'agentic coding workflows'],
  },
]

export type Role = {
  company: string
  title: string
  dates: string
  team: string
  highlights: string[]
}

export const experience: Role[] = [
  {
    company: 'Atlassian',
    title: 'Software Engineer',
    dates: 'Oct 2021 – Oct 2025',
    team: "Growth organization — built experiences across Atlassian's product (Jira, Confluence), billing, and marketing platforms.",
    highlights: [
      "Planned, scoped, and executed experimental feature development across Atlassian's suite of products.",
      "Partnered with engineering/product teams across Atlassian's global workforce to secure buy-in on upcoming features, keep stakeholders aligned, and ensure changes met each team's requirements for working in their codebases.",
      "Rebuilt the frontend for Atlassian's primary billing flow and expanded Confluence payments to non-admin users, working on small 2–3 engineer teams.",
      "Built product bundling functionality into Atlassian's checkout flow, contributing $3.5M in incremental ARR.",
    ],
  },
  {
    company: 'Dropbox',
    title: 'Software Engineer',
    dates: 'Sep 2020 – Oct 2021',
    team: 'HelloSign product team — built the HelloSign eSignature experience within the Dropbox core product.',
    highlights: [
      "Integrated the HelloSign (now Dropbox Sign) product into Dropbox's core suite over 5 months on a 6-person engineering team.",
      'Built features spanning the Dropbox and HelloSign codebases in PHP, Python, React, and Node.js.',
    ],
  },
  {
    company: 'Dropbox',
    title: 'Web Developer',
    dates: 'May 2019 – Sep 2020',
    team: 'HelloSign marketing team — owned and maintained the HelloSign marketing website.',
    highlights: [
      'Designed and built localization infrastructure for the HelloSign marketing site in 3 months, supporting 22 languages, working in lockstep with product engineering.',
      'Led vendor assessment and procurement for technical marketing and localization initiatives.',
      'Served as the only technical employee in the marketing department — translated engineering problems for marketing and design peers, and was a liaison between marketing and product engineering teams.',
    ],
  },
  {
    company: 'Atlassian',
    title: 'Web Producer',
    dates: 'Jan 2018 – May 2019',
    team: "Buyer Experience team — led a team of web producers, tasked with building experiences across Atlassian's marketing web properties.",
    highlights: [
      "Built landing pages, microsites, and informational materials using Atlassian's internal content management system for marketing properties.",
      'Developed a Node.js backend for a real-time voting service used live by ~1,000 audience participants during Atlassian\'s keynote at its 2018 Barcelona conference.',
    ],
  },
  {
    company: 'Apple (via WeLocalize)',
    title: 'Production Designer / Vendor Project Manager',
    dates: 'Jun 2016 – Jan 2018',
    team: 'Localization & Release Engineering — led a team of production designers, tasked with crafting localized documentation for all Apple products. Wrote software to support their workflow and migrate the team away from slow, legacy tools.',
    highlights: [
      'Built a real-time productivity-tracking service (Python, React, MySQL, Socket.io) serving a 20-person team for 2+ years.',
      'Developed custom quality-assurance software, reducing time spent manually peer-reviewing work.',
    ],
  },
]

export const education = {
  degree: 'Bachelor of Science',
  school: 'California Polytechnic State University, San Luis Obispo, CA',
}
