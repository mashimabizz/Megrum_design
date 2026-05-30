import {
  createContext,
  useContext,
  type PropsWithChildren,
} from "react";

type ProfileDrawerContextValue = {
  openDrawer: () => void;
};

const ProfileDrawerContext = createContext<ProfileDrawerContextValue>({
  openDrawer: () => undefined,
});

export function ProfileDrawerProvider({
  children,
  openDrawer,
}: PropsWithChildren<ProfileDrawerContextValue>) {
  return (
    <ProfileDrawerContext.Provider value={{ openDrawer }}>
      {children}
    </ProfileDrawerContext.Provider>
  );
}

export function useProfileDrawer() {
  return useContext(ProfileDrawerContext);
}
