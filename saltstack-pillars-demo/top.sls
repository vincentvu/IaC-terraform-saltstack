base:
  '*':
    - base.ntp
  'roles:wordpress':
    - match: grain
    - wordpress
