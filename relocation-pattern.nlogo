extensions [ gis ]

globals [ cities-dataset rivers-dataset amazon-dataset roads-dataset ]

breed [ centers center ]
breed [ settlements settlement ]
breed [ migrants migrant ]

patches-own [ land-value population water transportation urban-area? poptype growth-center? score move? ]
turtles-own [ types ]


;; Initializing study area settings
to setup
  clear-all
  ask patches [set pcolor white
    set land-value 0
    set population 0
    set water 0
    set transportation 0]
  set cities-dataset gis:load-dataset "Amazon/cities.shp"
  set rivers-dataset gis:load-dataset "Amazon/water.shp"
  set amazon-dataset gis:load-dataset "Amazon/studyarea.shp"
  set roads-dataset gis:load-dataset "Amazon/roads.shp"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of cities-dataset)
                                                (gis:envelope-of rivers-dataset)
                                                (gis:envelope-of amazon-dataset)
                                                (gis:envelope-of roads-dataset))
  reset-ticks

end


to display-amazon
  gis:set-drawing-color black
  gis:draw amazon-dataset 1

end


to display-rivers
  gis:set-drawing-color 97
  gis:draw rivers-dataset 1
  gis:fill rivers-dataset blue

  let waters patches with [gis:intersects? rivers-dataset self]   ;; identify patches on rivers-dataset
  ask waters [ ask patches in-radius river-radius [
      set water 10 ]
  ]


  repeat 5[
  diffuse water 0.5
  ;ask patches [ set water round water ]
  ]

end


to display-roads
  gis:set-drawing-color 37
  gis:draw roads-dataset 1

  let roads patches with [gis:intersects? roads-dataset self] ;; identify patches on roads-dataset
  ask roads [
    ask patches in-radius road-radius [
      set transportation 10
      ]
    ]

  repeat 5 [
    diffuse transportation 0.5
   ; ask patches [set transportation round transportation]
    ]

end


to display-cities
  gis:set-drawing-color 17
  gis:draw cities-dataset 1
  gis:fill cities-dataset 2.0

  let cities patches with [gis:intersects? cities-dataset self] ;; identify patches on cities-dataset
  ask cities [
    set urban-area? true
    ask patches in-radius city-radius [
      set population random-poisson 20  ;; Using 'random-poisson' here seems to be a good way, as the occurance of cities is a poisson point process!
      set water [water] of self + random-poisson 20
      set land-value [land-value] of self + random-poisson 20
      set transportation [transportation] of self + random-poisson 20
      ]
  ]

  repeat 5[
    diffuse population 0.5

    ask patches [
    set population round population
    ]
  ]

end


;; initializing informal settlements near river
to settle
  create-settlements number-of-settlements [
    set color yellow
    set shape "circle"
    set size 1
    ]

  let waters patches with [gis:intersects? rivers-dataset self]   ;; identify patches on rivers-dataset

  ;; stochastically allocate settlements to waterfront
  ask settlements [
    move-to one-of waters
    fd random 4
    ask patches in-radius 3 [
    set population ([population] of self + random 10)]  ;; this seems to be a good way to randomize population of each settlements
    ]


  repeat 5[
  diffuse population 0.5  ;; the value here need more consideration
    ask patches [set population round population]
  ]


end


;; some of the original settlers move from their initial locations to the urban areas nearby.
to decide-migration
  let cities patches with [gis:intersects? cities-dataset self] ;; identify patches on cities-dataset

  ;; randomly select a number of (default value: 100) settlements willing to migrate
  create-migrants migrate [
    move-to one-of settlements
    set shape "default"
    set size 3
    set color green
    ask patches in-radius 3 [
    set population ([population] of self + random 10)]
    if count cities in-radius 10 >= 1 [    ;; if there are at least 1 cities in 10 radius of the settlements
    face one-of (cities in-radius 10)  ;; ready to migrate to a city nearby
   ; ask other migrants [die]
    ask settlements-here [die
      ask patches in-radius 3 [set population [population] of self - random 10]
      ]   ;; replace the original settlements to migrants, remove populations
    ]
  ]

  repeat 5[
  diffuse population 0.5

  ask patches [
    set population round population ]
  ]



end


to migration

  ask migrants [
    ifelse [urban-area?] of patch-ahead 1 = true [  ;;;; ask patches: set population and poptype
      fd -1.1
      set color 53
      ]
    [
      forward 1
      set population ( [population] of self + random 10)
      ]
  ]

    tick

    if count migrants with [ color != 53 ] < 2 [
      stop
      ]   ;; if there are less than 2 migrates with dark green color, stop.

end


;; migrates evaluate urban conditions
to calculate


 ask patches [ set score sum [population * population-coefficient + water * water-coefficient + transportation * transportation-coefficient + land-value * land-value-coefficient] of patches in-radius 10]
 let best max [score] of patches
 let average mean [score] of patches
 ask patches with [score = best] [sprout-centers 1[
     set color green
   set size 10
   set shape "circle"]
 ]

  ask patches with [score <= average + 6 and score >= average - 6] [sprout-centers 1[
     set color yellow
   set size 10
   set shape "circle"]
 ]

print ( word "The best score of all patches is " best "." )
print ( word "The average score of all patches is " average "." )
print ( word "the number of patches with above-average score is " count patches with [score > average and score <= best] ", among a total number of " count patches " patches." )

end

to clear-calculation
  ask centers [die]
  ask patches [set pcolor white]
end

to visualize
  ask patches [set pcolor
    round (score / (mean [score] of patches * 1 ))
      ]



end

;; ask turtles move to the patch in-radius 10 with the max total score
to step
    ask turtles[
      let better max [score] of patches in-radius searching-radius
      ask patches in-radius searching-radius with [score = better] [
        set move? true
       ; set pcolor white
        ]
    ]

      ask turtles [
        move-to one-of patches in-radius searching-radius with [
          move? = true
          ]
        set color 52
        ]

      tick

   if count turtles with [ color != 52 ] < 2 [
     ;ask settlements-here [die]
      stop ]



end


;; add growth centers at users

to add-growth-center
  if mouse-down?
  [ask patch mouse-xcor mouse-ycor[
      sprout-centers 1 [
        set size 3
        set shape "star"
        set color red
        set growth-center? true
        set growth-center? true
        ]
      ]
  ]


end

;to output
 ; set-current-plot "Histogram of score"
  ;histogram [population] of patches with [score > 0]

;end
