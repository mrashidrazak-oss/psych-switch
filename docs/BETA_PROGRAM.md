# Closed beta program kit

Everything you need to recruit a small set of clinician beta testers,
collect feedback, and iterate before App Store / Play Store launch.

---

## Goal

5–10 psychiatrists across Malaysia / Singapore / Indonesia using
PsychSwitch in real clinics for **4 weeks**, with a structured
feedback loop, before public launch.

Why 5–10 and not 50: at this size you get **deep** feedback (each
clinician feels personally heard) without drowning in coordination.
Bigger numbers come after.

---

## Recruitment criteria

A good beta tester:
- Currently practicing as a psychiatrist, psychiatry trainee, or
  mental-health pharmacist
- Sees ≥10 patients/week who could benefit from cross-titration
  decision support
- Active on email or WhatsApp (we won't chase via post)
- Willing to commit ~20 minutes/week of feedback for 4 weeks

Avoid:
- People who say yes out of politeness
- Anyone who can't share their MMC / professional ID number (the
  errata system asks for it)

---

## Recruitment email template

```
Subject: PsychSwitch beta — would you try it?

Dr [name],

I've been building a clinical decision-support app for psychotropic
cross-titration over the past year, and I'd value your eye on it
before public release.

PsychSwitch produces evidence-graded, citation-backed switching
schedules drawn from Maudsley 15th, BAP, NICE and the Malaysian CPGs.
It adapts to your patient's actual doses, flags interactions in the
overlap window, predicts side-effect profiles, and generates a
discharge summary you can paste into the EMR.

It's privacy-first — nothing leaves your device unless you tap Share.

The closed beta runs for 4 weeks starting [DATE]. I'm looking for
5-10 testers who:
  • Will use it on ≥3 real cases during the beta
  • Will share 1 feedback note per week (template attached)

In return:
  • Early access to every feature
  • Direct line to me for any clinical question or bug
  • Acknowledgement on the app's About screen if you want it

If you're game, reply with:
  • Your Apple ID email (for TestFlight invite) and / or
  • Your Google Play email (for Android internal testing)
  • Country & institution

Thanks,
Rashid
```

---

## Distribution

### iOS — TestFlight
1. App Store Connect → My Apps → PsychSwitch ASEAN → TestFlight tab
2. Add testers individually (no public link — keep this closed)
3. Upload a build via `eas build --profile preview --platform ios`
4. Submit for TestFlight beta review (Apple takes 24–48h first time)
5. Once approved, testers get an email + the TestFlight app downloads it

Run a fresh build for each weekly iteration. Up to 10,000 external
testers; we'll stay well below that.

### Android — Play Console internal testing
1. Play Console → Testing → Internal testing
2. Create a tester list (email addresses)
3. Upload an .aab via `eas build --profile production --platform android`
4. Set the rollout to internal testers
5. Share the opt-in link via email

Internal testing has a **100-tester cap** but no review delay — the
build is live within ~30 min.

---

## Weekly feedback template

Copy this into a Google Form or send as a structured email. One per
tester per week.

```
PsychSwitch beta — week [N] feedback

1. How many switches did you run this week using PsychSwitch?
   ☐ 0     ☐ 1-2     ☐ 3-5     ☐ 6+

2. For one switch you remember most clearly: what was it (e.g.
   olanzapine 20 → aripiprazole 15)?
   ___________________________________

3. Did the schedule match what you would have prescribed manually?
   ☐ Yes, exactly
   ☐ Mostly — minor adjustments needed
   ☐ Notably different — concerned
   If "different" or "concerned": please describe.
   ___________________________________

4. Was the PsychSwitch Score's verdict (excellent / good / caution /
   poor) aligned with your clinical impression?
   ☐ Yes
   ☐ Off by one band — too high
   ☐ Off by one band — too low
   ☐ Strongly disagree
   Comment:
   ___________________________________

5. The most useful feature this week:
   ☐ Schedule itself
   ☐ Adapted dose scaling
   ☐ Citation chips
   ☐ PsychSwitch Score
   ☐ Predicted side-effect profile
   ☐ Discharge summary
   ☐ Counselling card
   ☐ PDF export
   ☐ Patient context warnings
   ☐ DDI checker
   ☐ Other: ____________

6. Any rule you'd flag for review? (Rule ID + concern)
   ___________________________________

7. Any feature you wished existed?
   ___________________________________

8. Any bug or rough edge?
   ___________________________________

9. Would you continue using PsychSwitch in your practice after the
   beta ends?
   ☐ Yes — would pay for it
   ☐ Yes — only if free
   ☐ Maybe — depends on improvements (which: ____________)
   ☐ No (why: ____________)

Thanks for your time.
```

---

## What "good feedback" looks like

A useful weekly response looks like this:

> Ran 4 switches this week. The olanzapine→quetiapine for a patient
> with weight gain rated me an 82 (good); I would have rated it ~60
> because quetiapine isn't really better metabolically than
> olanzapine. The Score may be over-weighting the AE alignment bonus
> because quetiapine is technically a "switch candidate" but it's a
> weak one. Also, the "merge duplicates" warning fired for my
> sertraline 75 → 62.5 step — I think the rounding was correct but
> the warning copy made me second-guess. Otherwise loved the
> citation chips. M15-Ch4-p412 actually does say what you say it says.

Every line in that response is actionable. Aim to elicit specifics.

---

## Success metrics for the beta

After 4 weeks, the beta is "successful" if:

- ≥80% of testers used PsychSwitch on ≥3 real cases
- ≥50% report PsychSwitch Score aligned with clinical impression
  "yes" or "off by one band"
- ≥0 catastrophic clinical errors reported (hard floor — any single
  one means we delay launch)
- ≥3 substantive improvement suggestions per tester per 4 weeks
- ≥70% answer "would continue using" yes (paid or free)

If those numbers don't hit, iterate for another 4 weeks before
shipping.

---

## After beta

1. Aggregate the feedback into a v0.5 changelog.
2. Acknowledge testers (with permission) on the About screen.
3. Submit to App Store + Play Console for external launch.
4. Open a public TestFlight link for ongoing pre-release access.
