export type RouteMeta = {
  path: string
  title: string
  description: string
}

export const routeMeta: RouteMeta[] = [
  {
    path: '/',
    title: 'Andrew DaRe — Software Engineer',
    description:
      'Andrew DaRe, full-stack software engineer with experience shipping billing, growth, and real-time features at Dropbox and Atlassian.',
  },
  {
    path: '/experience',
    title: 'Experience — Andrew DaRe',
    description:
      "Andrew DaRe's professional experience across Atlassian, Dropbox, and Apple, plus key competencies and education.",
  },
  {
    path: '/contact',
    title: 'Contact — Andrew DaRe',
    description: 'Get in touch with Andrew DaRe by email, GitHub, or LinkedIn.',
  },
]

export function getRouteMeta(path: string): RouteMeta {
  return routeMeta.find((route) => route.path === path) ?? routeMeta[0]
}
