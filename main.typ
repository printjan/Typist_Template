#import "template.typ": conf
#import "configs/summary_vertical.typ": print-profile
//#import "configs/exam_notes_horizontal.typ": print-profile

// Optionally: individually fine-tune parameters
// #let print-profile = print-profile + (
//   body-size: 4.6pt,
//   body-leading: 2.1pt,
//   paragraph-spacing: 3.2pt,
// )

#show: doc => conf(
  profile: print-profile,
  doc,
)

// Include individual chapters (files located in chapters/)
#include "chapters/tutorial.typ"
