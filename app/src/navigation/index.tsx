// 画面遷移（README セクション6）
// native-stack: onboard / scan / memory / space + 下部タブ(home / memories / settings)
import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import type { RootStackParamList, TabParamList } from './types';
import { useStore } from '../store/Store';
import BottomNav from '../components/BottomNav';
import OnboardScreen from '../screens/OnboardScreen';
import HomeScreen from '../screens/HomeScreen';
import MemoriesScreen from '../screens/MemoriesScreen';
import SettingsScreen from '../screens/SettingsScreen';
import ScanScreen from '../screens/ScanScreen';
import MemoryScreen from '../screens/MemoryScreen';
import SpaceScreen from '../screens/SpaceScreen';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<TabParamList>();

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{ headerShown: false }}
      tabBar={(props) => <BottomNav {...props} />}
    >
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Memories" component={MemoriesScreen} />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}

export default function RootNavigator() {
  const { onboarded } = useStore();
  return (
    <Stack.Navigator
      initialRouteName={onboarded ? 'Main' : 'Onboard'}
      screenOptions={{
        headerShown: false,
        animation: 'fade', // 画面切替: fade 0.28s
        animationDuration: 280,
      }}
    >
      <Stack.Screen name="Onboard" component={OnboardScreen} />
      <Stack.Screen name="Main" component={MainTabs} />
      <Stack.Screen name="Scan" component={ScanScreen} />
      <Stack.Screen name="Memory" component={MemoryScreen} />
      <Stack.Screen name="Space" component={SpaceScreen} />
    </Stack.Navigator>
  );
}
