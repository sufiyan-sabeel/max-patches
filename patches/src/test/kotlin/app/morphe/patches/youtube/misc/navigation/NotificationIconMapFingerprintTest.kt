/*
 * Copyright 2026 MAX Patcher contributors.
 * https://github.com/sufiyan-sabeel/max-patches
 *
 * Licensed under the GNU General Public License v3.0, with the additional GPLv3 section 7 terms in
 * NOTICE. Derived from Morphe Patches, see NOTICE for the upstream attribution.
 */

package app.morphe.patches.youtube.misc.navigation

import kotlin.test.Test
import kotlin.test.assertSame

/**
 * The version guard, which is the part of the 21.45 fix that can regress silently.
 *
 * YouTube 21.45.82 does not ship `yt_fill_bell_black_24`; its navigation icon map carries
 * `yt_outline_bell_vd_theme_24` instead (verified against the APK's resource table and DEX). The
 * wrong branch here reintroduces the original failure on one side of the version line, so both
 * branches are asserted.
 *
 * These tests do not prove that a fingerprint resolves against a real APK — that needs the APK, and
 * the tests in the APK-backed suites cover it.
 */
class NotificationIconMapFingerprintTest {

    @Test
    fun `21 45 and later anchor on the outline bell`() {
        assertSame(
            SetEnumMapCairoFingerprint,
            notificationIconMapFingerprint(is2145OrGreater = true)
        )
    }

    @Test
    fun `older versions keep the original anchor`() {
        assertSame(
            SetEnumMapFingerprint,
            notificationIconMapFingerprint(is2145OrGreater = false)
        )
    }
}
