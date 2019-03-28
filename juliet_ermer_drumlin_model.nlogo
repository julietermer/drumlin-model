extensions [
  gis
]

globals [
 total-patch-height
 net-deposited
 net-eroded
 total-number-of-patches
 stiff-patches
 percent-of-white-patches
 mean-patch-height
 mean-velocity
 ice-thickness
 mean-relief
 max-relief
 min-relief
]

patches-own [
  patch-height
  velocity
  patch-infront
  stiff
  relief
]

to setup
  clear-all

  ask patches [
    set patch-height initial-sediment-thickness  ;; set patch height to thickness, chosen by slider

    set patch-infront patch-at 0 1
    set relief patch-height - [patch-height] of patch-infront
  ]

  ask patches with [ patch-height > 0 ]  ;; ask patches with sediment to ...
  [ set pcolor (scale-color blue patch-height 100 0) ]  ;; set their colour dependant on their patch height - darker = taller

  set total-patch-height sum [ patch-height ] of patches  ;; reset total-patch-height
  set net-deposited 0
  set net-eroded 0
  set total-number-of-patches count patches
  set percent-of-white-patches 0
  set mean-patch-height 0
  set mean-velocity 0
  set mean-relief 0
  set max-relief 0
  set min-relief 0
  set ice-thickness 100 - temperature  ;; iverse relationship - as it warms, ice thins

  ask patches [  ;; choosing which patches are going to be stiff ...
    let random-number random 100
    ifelse random-number < 98 [  ;; much higher probability of being unstiff ...
      set stiff false  ;; if lower than 98, set as unstiff
    ] [
      set stiff true  ;;  else set as stiff
    ]
  ]

  set sediment-availability 50 ;; (equilibrium point of net deposition and erosion)
  reset-ticks
end

to go
  ask patches [
    calculate-velocity
    set relief patch-height - [patch-height] of patch-infront
  ]

  if total-patch-height < 0 [ stop ]
  ;if ticks = 300 [ export-world-raster ]
  ;if ticks = 301 [ stop ]

  sediment-distribute
  sediment-deposit-erode
  sediment-instability-relief

  sediment-availability-reduce
  adjust-ice-thickness

  ask patches with [ patch-height > 0 ]  ;; ask patches with sediment to ...
  [ set pcolor (scale-color blue patch-height 100 1) ]  ;; set their colour depepndent on their patch height - darker = taller

  set total-patch-height sum [ patch-height ] of patches  ;; adjust total-patch-height
  set total-number-of-patches count patches ;; adjust number-of-patches
  set percent-of-white-patches ( count patches with [ patch-height <= 0 ] / count patches ) * 100
  set mean-patch-height mean [ patch-height ] of patches
  set mean-velocity mean [ velocity ] of patches
  set mean-relief mean [ relief ] of patches
  set max-relief max [ relief ] of patches
  set min-relief min [ relief ] of patches

  tick
end

to calculate-velocity
  set velocity random ( (temperature + ice-thickness + relief) / 3 ) * 0.1 ;; ... define velocity based on temperature, ice thickness AND patch height difference (relief) (dividing by 3 to give a small number under 100)
end

to adjust-ice-thickness
 set ice-thickness (100 - temperature )
end

to sediment-distribute
  if any? patches with [ patch-height > maximum-patch-height] [  ;; if there are patches taller than the maximum ...
    ask patches with [ patch-height > maximum-patch-height ] [  ;; ask these patches to ...

      distribution-direction

    ]
  ]

end

to distribution-direction
      let sediment-change (patch-height + ice-thickness) * 0.1 ;; define how much they will lose - taller the patch and thicker the ice, the more they lose - bc more pressure

      ;;; first try to distribute to the patch infront - preferential forward motion ;;;
      let distributed false  ;; keep track if deposition has occurred so the same patch doesn't give sediment more than once
      if [ patch-height ] of patch-infront <= patch-height [  ;; if the patch infront is shorter or equal in height ...
          set patch-height patch-height - sediment-change  ;;  take the sediment from the giving patch
          ask patch-infront [  ;; then ask the patch infront to ...
            set patch-height patch-height + sediment-change  ;; ... recieve the sediment
          ]
          set distributed true  ;; signal that distribution has ocurred
        ]

      ;;; when the patches infront are not available (too tall), distribute to any of the other neighbours randomly ;;;
      if not distributed [  ;; if distribution has still not occurred because infront is too tall ...
        set patch-height patch-height - sediment-change  ;; remove sediment from the patch in preparation
        let random-number random 8  ;; define a random number from 1-7 (to decide which patch will get depositd on)

        ;;; try front right diagonal ;;;
        if random-number = 1 and [ patch-height ] of patch-at 1 1 <= patch-height [  ;; if scenario 1 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at 1 1 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try front left diagonal ;;;
        if random-number = 2 and [ patch-height ] of patch-at -1 1 <= patch-height [  ;; if scenario 2 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at -1 1 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try right ;;;
        if random-number = 3 and [ patch-height ] of patch-at 1 0 <= patch-height [  ;; if scenario 3 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at 1 0 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try left ;;;
        if random-number = 4 and [ patch-height ] of patch-at -1 0 <= patch-height [  ;; if scenario 4 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at -1 0 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try back right diagonal ;;;
        if random-number = 5 and [ patch-height ] of patch-at 1 -1 <= patch-height [  ;; if scenario 5 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at 1 -1 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try back left diagonal ;;;
        if random-number = 6 and [ patch-height ] of patch-at -1 1 <= patch-height [  ;; if scenario 6 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at -1 1 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]

        ;;; try behind ;;;
        if random-number = 7 and [ patch-height ] of patch-at 0 -1 <= patch-height [  ;; if scenario 7 is chosen and this patch is shorter than or equal to the giving middle patch
          ask patch-at 0 -1 [  ;; ask this patch to ...
            set patch-height patch-height + sediment-change  ;; recieve the sediment
          ]
          set distributed true  ;; signal that it has been recieved
        ]
      ]

      if not distributed [  ;; if still not distributed because all of the surrounding patches are too tall ...
        set patch-height patch-height + sediment-change  ;; ... let the patch keep its sediment and hold it until this changes
      ]
end

to sediment-deposit-erode  ;; 50 = equilibrium where neither occurs
  if sediment-availability > 50 [  ;; if sediment-availability is > half (above equilibrium line) ... set the system into net deposition below
    let number-of-patches-to-deposit ( total-number-of-patches * sediment-availability * 0.0025 )  ;; the higher the sediment availability, the more patches are chosen to be deposited on (dividing to make it a sensible number)

    ask n-of random number-of-patches-to-deposit patches [
      let deposit-amount ( patch-height * sediment-availability ) / 5000  ;; the taller the patch and the more sediment available, the more is deposited (bc deposition more likely on large obstacles)
      set patch-height patch-height + deposit-amount  ;; deposit on these patches
      set net-deposited net-deposited + deposit-amount
    ]
  ]

  if sediment-availability > 1 and sediment-availability < 50 [  ;; if sediment-availability is > half (and greater than 0 so not dividing by 0) ... set the system into net erosion below
    let number-of-patches-to-erode ( ( total-number-of-patches / sediment-availability ) / 2 ) ;; the higher the sediment availability, the less patches are chosen to be eroded - dividing by 2 to make not so many patches erode


    ask n-of random number-of-patches-to-erode patches [
      let erode-amount ( ( 2 * ice-thickness ) * ( patch-height ) ) / 1000  ;; define the erosion amount - the thicker the ice (pressure proxy) and the taller the patch, the more erosion
        set patch-height patch-height - erode-amount  ;; erode these patches
        set net-eroded net-eroded + erode-amount
    ]
  ]
end

to sediment-instability-relief  ;;
  ask patches [
    if stiff = false or (stiff = true and ((random 100) < 10)) [ ;; only unstiff patches and a random amount of stiff patches continue ... higher the number the more stiff ones move (less are truely stiff)
    let sediment-change random 11  ;; define a random number from 0-10 - how many grains a patch will lose

    if sediment-change > patch-height [  ;; if x is greater than the patch-height, it would go into negative sediment ...
      set sediment-change patch-height  ;; ... so just take all of the sediment that that patch has
    ]

    let amount-to-move velocity
    let patch-and-patches-infront-unsorted patches with [ pxcor = [ pxcor ] of myself and pycor >= [ pycor ] of myself and pycor <= [ pycor + amount-to-move ] of myself ]  ;; choose patches infront within the limits of velocity
    let patch-and-patches-infront-sorted sort-on [ pycor ] patch-and-patches-infront-unsorted  ;; sort this group of patches from y coordinates lowest to highest (to resolve issue of sediment going uphill - even if a patch is shorter than the original, if it has gone down it can't go back up

    let deposited false  ;; keeps track of whether there has already been a deposit ahead of the patch

      ifelse relief > 40 [  ;; if relief is greater than zero (patch is taller than the one infront of it - setting up positive feedback between relief and sediment mobility ...
        foreach patch-and-patches-infront-sorted [  ;; for each of the sorted patches ahead
        the-patch -> ask the-patch [  ;; ask the patch to ...
        let patch-infront-height [ patch-height ] of patch-infront  ;; set the patch infronts height to that of the patch infront
        if not deposited  [  ;; if deposition hasn't occured yet
          ask myself [ set patch-height patch-height - sediment-change  ;;  decrease patch-height by x
          ]

          set patch-height patch-height + sediment-change  ;; give the receiving patch the sediment
          set deposited true  ;; signal that you have deposited
          ]
        ]
      ]

      ]

      [
        foreach patch-and-patches-infront-sorted [  ;; for each of the sorted patches ahead ...
        the-patch -> ask the-patch [  ;; ask the patch to ...
        let patch-infront-height [ patch-height ] of patch-infront  ;; set the patch infronts height to that of the patch infront
        if not deposited and patch-infront-height > patch-height [  ;; if deposition hasn't occured yet and the patch ahead of the patch is taller
          ask myself [ set patch-height patch-height - sediment-change  ;;  decrease patch-height by x
          ]

          set patch-height patch-height + sediment-change  ;; give the receiving patch the sediment
          set deposited true  ;; signal that you have deposited
          ]
        ]
      ]
      ]

     if not deposited [  ;; if the for loops ends without depositing ...
        set patch-height patch-height - sediment-change  ;;  decrease patch-height by x
        set deposited true  ;; signal that you have deposited ...
        let patch-to-deposit patch-at 0 (amount-to-move)  ;; define the patch to deposit at x coord = 0 and y coord = 11 - random(0-10)
          ask patch-to-deposit [  ;; ... at the furthest possible patch for that grain size
            set patch-height patch-height + sediment-change  ;; ... deposit the sediment
        ]
      ]
  ]
  ]
end


to sediment-availability-reduce
  if ticks >= 100 [
    set sediment-availability sediment-availability * 0.99  ;; reduce sediment by 1% each tick
  ]
end


to export-world-raster
  gis:set-transformation (list min-pxcor max-pxcor min-pycor max-pycor) (list min-pxcor max-pxcor min-pycor max-pycor) ;; setting transformation from netlogo to gis - first list is what gis coordinates will be and second is what netlogo is - put both same
ask patches [
    gis:store-dataset gis:patch-dataset patch-height "patch-height-export-final-300-10"  ;; store a data set of patch's patch-height - in an asc file
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
718
519
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
99
0
99
1
1
1
ticks
30.0

SLIDER
11
175
183
208
temperature
temperature
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
11
219
183
252
sediment-availability
sediment-availability
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
9
266
184
299
maximum-patch-height
maximum-patch-height
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
20
34
83
67
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
98
34
161
67
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
77
161
110
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
311
186
344
initial-sediment-thickness
initial-sediment-thickness
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
738
307
851
352
NIL
total-patch-height
2
1
11

MONITOR
739
360
851
405
NIL
mean-patch-height
2
1
11

MONITOR
857
360
995
405
NIL
percent-of-white-patches
2
1
11

MONITOR
857
307
994
352
NIL
total-number-of-patches
17
1
11

MONITOR
739
462
852
507
NIL
net-eroded
2
1
11

MONITOR
859
463
996
508
NIL
net-deposited
17
1
11

MONITOR
739
411
853
456
NIL
mean-velocity
2
1
11

MONITOR
858
411
995
456
NIL
ice-thickness
17
1
11

MONITOR
1001
307
1072
352
NIL
mean-relief
17
1
11

MONITOR
1003
360
1072
405
NIL
max-relief
17
1
11

MONITOR
1004
411
1073
456
NIL
min-relief
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model represents drumlin formation and evolution over time, through simple interactions, showing how they may form through self-organisation.

## HOW IT WORKS

Each patch has colour that represents patch-height from 0-100 (darker = taller). Patches redistribute sediment to each other, resulting in an undulating drumlin field over time.

## HOW TO USE IT

The model is automatically set to its deafulat values, so just press setup and go!

## THINGS TO TRY

Try altering the different input sliders and observing how the resultant landforms change.

## EXTENDING THE MODEL

Try adding in other parameters or mechanisms that you believe may be important for drumlin formation.

## RELATED MODELS

The sandpile model in the Chemistry and Physics library.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="practice sensitivity inital thickness" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>total-patch-height</metric>
    <metric>mean-patch-height</metric>
    <metric>median-patch-height</metric>
    <metric>total-number-of-patches</metric>
    <metric>percent-of-white-patches</metric>
    <metric>mean-velocity</metric>
    <metric>median-velocity</metric>
    <metric>net-eroded</metric>
    <metric>net-deposited</metric>
    <metric>ice-thickness</metric>
    <enumeratedValueSet variable="initial-sediment-thickness">
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="practice sensitivity sediment availability" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>total-patch-height</metric>
    <metric>mean-patch-height</metric>
    <metric>median-patch-height</metric>
    <metric>total-number-of-patches</metric>
    <metric>percent-of-white-patches</metric>
    <metric>mean-velocity</metric>
    <metric>median-velocity</metric>
    <metric>net-eroded</metric>
    <metric>net-deposited</metric>
    <metric>ice-thickness</metric>
    <enumeratedValueSet variable="initial-sediment-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
      <value value="45"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="practice sensitivity ice thickness" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>total-patch-height</metric>
    <metric>mean-patch-height</metric>
    <metric>median-patch-height</metric>
    <metric>total-number-of-patches</metric>
    <metric>percent-of-white-patches</metric>
    <metric>mean-velocity</metric>
    <metric>median-velocity</metric>
    <metric>net-eroded</metric>
    <metric>net-deposited</metric>
    <enumeratedValueSet variable="initial-sediment-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ice-thickness">
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="practice sensitivity temperature" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>total-patch-height</metric>
    <metric>mean-patch-height</metric>
    <metric>median-patch-height</metric>
    <metric>total-number-of-patches</metric>
    <metric>percent-of-white-patches</metric>
    <metric>mean-velocity</metric>
    <metric>median-velocity</metric>
    <metric>net-eroded</metric>
    <metric>net-deposited</metric>
    <metric>ice-thickness</metric>
    <enumeratedValueSet variable="initial-sediment-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ice-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="practice sensitivity maximum-patch-height" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>total-patch-height</metric>
    <metric>mean-patch-height</metric>
    <metric>median-patch-height</metric>
    <metric>total-number-of-patches</metric>
    <metric>percent-of-white-patches</metric>
    <metric>mean-velocity</metric>
    <metric>median-velocity</metric>
    <metric>net-eroded</metric>
    <metric>net-deposited</metric>
    <enumeratedValueSet variable="initial-sediment-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ice-thickness">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="temperature ce thickness" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>ask patches [ mean (ice-thickness) ]</metric>
    <enumeratedValueSet variable="sediment-availability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature">
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-patch-height">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
