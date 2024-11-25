<script setup>
import { useApplicationStore } from '@/stores/applications'
const props = defineProps(['id', 'title'])
const applications = useApplicationStore()

function setActiveIndex(index) {
  applications.setActiveIndex(index)
}
</script>

<template>
  <button
    class="taskbar-button"
    :class="{
      'taskbar-button__active': applications.getActiveIndex === props.id,
    }"
    @click="setActiveIndex(props.id)"
  >
    {{ props.title }}
  </button>
</template>

<style lang="scss">
.taskbar-button {
  flex: 1;
  max-width: 20rem;
  height: 3rem;
  font-size: 1.6rem;
  background-color: $color-gray;
  border-top: 1px solid $color-white;
  border-left: 1px solid $color-white;
  border-right: 1px solid $color-gray-dark;
  border-bottom: 1px solid $color-gray-dark;
  box-shadow: 1px 1px 0px #000000;
  text-align: left;
  padding-left: 0.6rem;

  &__active {
    background-color: $color-gray-light;
    border-top: 1px solid $color-gray-dark;
    border-left: 1px solid $color-gray-dark;
    border-right: 1px solid $color-white;
    border-bottom: 1px solid $color-white;
    box-shadow: -1px -1px 0px #000000;
    margin-top: 1px;
  }
}
</style>
