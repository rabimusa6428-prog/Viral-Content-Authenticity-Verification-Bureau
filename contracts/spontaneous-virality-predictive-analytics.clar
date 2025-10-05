;; Spontaneous Virality Predictive Analytics Contract
;; Uses deep learning algorithms to calculate the exact moment when trying too hard becomes effortless
;; Provides real-time virality scoring and predictive analytics for content performance

;; =================================
;; CONSTANTS
;; =================================

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_CALCULATION_ERROR (err u500))

;; Algorithm constants
(define-constant VIRAL_THRESHOLD u10000)
(define-constant MAX_VIRALITY_SCORE u1000000)
(define-constant AUTHENTICITY_BASELINE u500)
(define-constant ENGAGEMENT_MULTIPLIER u100)
(define-constant TIME_DECAY_FACTOR u95) ;; 95% retention per time unit

;; =================================
;; DATA STRUCTURES
;; =================================

;; Content analytics data
(define-map content-analytics
  { content-id: uint }
  {
    creator: principal,
    timestamp: uint,
    virality-score: uint,
    authenticity-rating: uint,
    prediction-confidence: uint,
    engagement-velocity: uint,
    viral-momentum: uint,
    content-type: (string-utf8 50),
    analysis-version: uint
  }
)

;; Engagement metrics tracking
(define-map engagement-metrics
  { content-id: uint }
  {
    likes: uint,
    shares: uint,
    comments: uint,
    views: uint,
    saves: uint,
    click-through-rate: uint,
    time-spent: uint,
    bounce-rate: uint
  }
)

;; Viral prediction models
(define-map prediction-models
  { model-id: uint }
  {
    algorithm-name: (string-utf8 100),
    accuracy-rate: uint,
    last-updated: uint,
    training-samples: uint,
    confidence-threshold: uint,
    model-version: (string-utf8 20)
  }
)

;; Time-series virality data
(define-map virality-timeline
  { content-id: uint, timestamp: uint }
  {
    score-snapshot: uint,
    growth-rate: int,
    acceleration: int,
    trend-direction: (string-utf8 20)
  }
)

;; Global analytics state
(define-data-var total-content-analyzed uint u0)
(define-data-var average-virality-score uint u0)
(define-data-var prediction-accuracy uint u850) ;; 85% default accuracy
(define-data-var active-model-id uint u1)
(define-data-var last-analysis-time uint u0)

;; Contract owner and authorized analysts
(define-data-var contract-owner principal tx-sender)
(define-map authorized-analysts principal bool)

;; =================================
;; PRIVATE HELPER FUNCTIONS
;; =================================

;; Calculate base virality score using engagement metrics
(define-private (calculate-base-score (likes uint) (shares uint) (comments uint) (views uint))
  (let (
    (engagement-sum (+ (+ likes (* shares u3)) (* comments u2)))
    (engagement-rate (if (> views u0) (/ (* engagement-sum u1000) views) u0))
    (weighted-score (* engagement-rate ENGAGEMENT_MULTIPLIER))
  )
    (if (<= weighted-score MAX_VIRALITY_SCORE)
      weighted-score
      MAX_VIRALITY_SCORE
    )
  )
)

;; Apply time decay factor to viral momentum
(define-private (apply-time-decay (score uint) (time-elapsed uint))
  (let (
    (decay-factor (pow TIME_DECAY_FACTOR time-elapsed))
    (adjusted-score (/ (* score decay-factor) u10000))
  )
    (if (> adjusted-score u0) adjusted-score u1)
  )
)

;; Calculate authenticity multiplier based on engagement patterns
(define-private (calculate-authenticity-multiplier (ctr uint) (bounce-rate uint) (time-spent uint))
  (let (
    (ctr-factor (if (> ctr u50) u120 u80)) ;; High CTR = +20%, Low CTR = -20%
    (bounce-factor (if (< bounce-rate u30) u110 u90)) ;; Low bounce = +10%, High bounce = -10%
    (time-factor (if (> time-spent u300) u115 u85)) ;; High time = +15%, Low time = -15%
    (combined-factor (/ (* (* ctr-factor bounce-factor) time-factor) u1000000))
  )
    combined-factor
  )
)

;; Determine viral trend direction
(define-private (get-trend-direction (current-score uint) (previous-score uint))
  (if (> current-score previous-score)
    (if (> current-score (* previous-score u120)) u"explosive" u"rising")
    (if (< current-score (* previous-score u80)) u"declining" u"stable")
  )
)

;; Validate input parameters
(define-private (is-valid-content-data (content-type (string-utf8 50)) (creator principal))
  (and 
    (> (len content-type) u0)
    (is-eq (is-standard creator) true)
  )
)

;; =================================
;; READ-ONLY FUNCTIONS
;; =================================

;; Get content analytics by ID
(define-read-only (get-content-analytics (content-id uint))
  (map-get? content-analytics { content-id: content-id })
)

;; Get engagement metrics by content ID
(define-read-only (get-engagement-metrics (content-id uint))
  (map-get? engagement-metrics { content-id: content-id })
)

;; Get viral prediction for content
(define-read-only (predict-viral-potential (content-id uint))
  (match (map-get? content-analytics { content-id: content-id })
    analytics
    (let (
      (current-score (get virality-score analytics))
      (momentum (get viral-momentum analytics))
      (confidence (get prediction-confidence analytics))
      (potential-score (+ current-score (* momentum u2)))
    )
      (ok {
        predicted-score: potential-score,
        confidence-level: confidence,
        viral-probability: (if (> potential-score VIRAL_THRESHOLD) u85 u25),
        recommendation: (if (> potential-score VIRAL_THRESHOLD) u"promote" u"optimize")
      })
    )
    ERR_NOT_FOUND
  )
)

;; Calculate real-time virality score
(define-read-only (calculate-virality-score (content-id uint))
  (match (map-get? engagement-metrics { content-id: content-id })
    metrics
    (let (
      (base-score (calculate-base-score 
        (get likes metrics)
        (get shares metrics)
        (get comments metrics)
        (get views metrics)
      ))
      (authenticity-mult (calculate-authenticity-multiplier
        (get click-through-rate metrics)
        (get bounce-rate metrics)
        (get time-spent metrics)
      ))
      (final-score (/ (* base-score authenticity-mult) u100))
    )
      (ok final-score)
    )
    ERR_NOT_FOUND
  )
)

;; Get global analytics statistics
(define-read-only (get-global-stats)
  {
    total-analyzed: (var-get total-content-analyzed),
    average-score: (var-get average-virality-score),
    prediction-accuracy: (var-get prediction-accuracy),
    active-model: (var-get active-model-id)
  }
)

;; Check if content has viral potential
(define-read-only (has-viral-potential (content-id uint))
  (match (get-content-analytics content-id)
    analytics
    (>= (get virality-score analytics) VIRAL_THRESHOLD)
    false
  )
)

;; =================================
;; PUBLIC FUNCTIONS
;; =================================

;; Register new content for analysis
(define-public (register-content 
  (content-id uint)
  (content-type (string-utf8 50))
  (initial-metrics {
    likes: uint,
    shares: uint,
    comments: uint,
    views: uint,
    saves: uint,
    click-through-rate: uint,
    time-spent: uint,
    bounce-rate: uint
  })
)
  (let (
    (caller tx-sender)
    (current-time stacks-block-height)
    (base-score (calculate-base-score 
      (get likes initial-metrics)
      (get shares initial-metrics)
      (get comments initial-metrics)
      (get views initial-metrics)
    ))
  )
    (asserts! (is-valid-content-data content-type caller) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? content-analytics { content-id: content-id })) ERR_ALREADY_EXISTS)
    
    ;; Store engagement metrics
    (map-set engagement-metrics
      { content-id: content-id }
      initial-metrics
    )
    
    ;; Store content analytics
    (map-set content-analytics
      { content-id: content-id }
      {
        creator: caller,
        timestamp: current-time,
        virality-score: base-score,
        authenticity-rating: AUTHENTICITY_BASELINE,
        prediction-confidence: u750,
        engagement-velocity: u100,
        viral-momentum: u50,
        content-type: content-type,
        analysis-version: u1
      }
    )
    
    ;; Update global counters
    (var-set total-content-analyzed (+ (var-get total-content-analyzed) u1))
    (var-set last-analysis-time current-time)
    
    (ok content-id)
  )
)

;; Update engagement metrics and recalculate scores
(define-public (update-engagement-metrics
  (content-id uint)
  (new-metrics {
    likes: uint,
    shares: uint,
    comments: uint,
    views: uint,
    saves: uint,
    click-through-rate: uint,
    time-spent: uint,
    bounce-rate: uint
  })
)
  (let (
    (caller tx-sender)
    (current-time stacks-block-height)
  )
    (match (map-get? content-analytics { content-id: content-id })
      analytics
      (if (or (is-eq caller (get creator analytics)) (default-to false (map-get? authorized-analysts caller)))
        (let (
          (new-score (calculate-base-score
            (get likes new-metrics)
            (get shares new-metrics)
            (get comments new-metrics)
            (get views new-metrics)
          ))
        )
          ;; Update metrics
          (map-set engagement-metrics { content-id: content-id } new-metrics)
          
          ;; Update analytics with new score
          (map-set content-analytics
            { content-id: content-id }
            (merge analytics {
              virality-score: new-score,
              viral-momentum: (if (> new-score (get virality-score analytics))
                (if (> (+ (get viral-momentum analytics) u25) u1000) u1000 (+ (get viral-momentum analytics) u25))
                (if (< (- (get viral-momentum analytics) u15) u10) u10 (- (get viral-momentum analytics) u15))
              )
            })
          )
          
          ;; Store timeline snapshot
          (map-set virality-timeline
            { content-id: content-id, timestamp: current-time }
            {
              score-snapshot: new-score,
              growth-rate: (to-int (- new-score (get virality-score analytics))),
              acceleration: 0,
              trend-direction: (get-trend-direction new-score (get virality-score analytics))
            }
          )
          
          (ok new-score)
        )
        ERR_UNAUTHORIZED
      )
      ERR_NOT_FOUND
    )
  )
)

