<script setup>
const props = defineProps(['iconSrc', 'title'])
</script>

<template>
  <button class="desktop-icon">
    <img :src="props.iconSrc" :alt="props.title" class="desktop-icon__image" />
    {{ props.title }}
  </button>
</template>

<style lang="scss">
.desktop-icon {
  border: none;
  background-color: transparent;
  color: $color-white;
  display: flex;
  align-items: center;
  flex-direction: column;
  gap: 1rem;
  font-size: 1.6rem;
  width: 10rem;
  height: 9.6rem;
  margin-top: 1rem;
  overflow: hidden;
  min-width: 0;

  &__image {
    width: 5rem;
  }
}
</style>
