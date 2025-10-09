#ifndef CODEQL_HOOK_H
#define CODEQL_HOOK_H

/* Header-only, no std headers. Implementation in tools/hooks/codeql_hook.c */

#ifdef __cplusplus
extern "C" {
#endif

/* --- Global toggle (0=off, nonzero=on). Default should be OFF in the .c file. */
void CustomHook_SetEnabled(int on);
int  CustomHook_IsEnabled(void);

/* Raw emitter: always writes one line to stderr (no enable check). */
void CustomPoint_HOOK_emit(const char* tag);

#ifdef __cplusplus
} /* extern "C" */
#endif

/*
 * Convenience macro:
 *   CustomPoint_HOOK("tag");
 * emits only when the global toggle is ON.
 * Safe in C and C++.
 */
#ifndef CustomPoint_HOOK
#define CustomPoint_HOOK(TAG)                       \
  do {                                              \
    if (CustomHook_IsEnabled()) {                   \
      CustomPoint_HOOK_emit((TAG));                 \
    }                                               \
  } while (0)
#endif

#endif /* CODEQL_HOOK_H */