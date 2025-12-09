--Fight Call - Vector Lock
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49	   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50		  -- "Fight Call"
local SET_AEROMANEUVER_ACE=0x1c49   -- "Aero Maneuver Ace" (다른 카드들과 세트코드 맞춰서 사용)

function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL,SET_AEROMANEUVER_ACE}

	--------------------------------
	-- (1) 발동:
	--	 자신 필드의 "Aero Maneuver Ace" 엑시즈를 대상으로,
	--	 그 랭크 ±3인 "Aero Maneuver Ace" 엑시즈를 엑덱에서 특소 (엑시즈 소환 취급)
	--	 → 특소한 몬스터는 턴 종료시까지 상대 카드 효과의 대상이 되지 않음
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- 자신 필드의 소재 후보: "Aero Maneuver Ace" 엑시즈 몬스터
-- → 엑덱에 랭크 차이가 정확히 3인 "Aero Maneuver Ace" 엑시즈가 있어야 함
--------------------------------
function s.xyzfilter_ex(c,e,tp,mc)
	if not (c:IsSetCard(SET_AEROMANEUVER_ACE) and c:IsType(TYPE_XYZ)) then return false end
	local rk1=mc:GetRank()
	local rk2=c:GetRank()
	if rk1<=0 or rk2<=0 then return false end
	if math.abs(rk2-rk1)~=3 then return false end
	return mc:IsCanBeXyzMaterial(c,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

function s.matfilter(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(SET_AEROMANEUVER_ACE) and c:IsType(TYPE_XYZ)
		and Duel.IsExistingMatchingCard(s.xyzfilter_ex,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end

--------------------------------
-- 타깃 지정
--------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.matfilter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.matfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--------------------------------
-- 발동 처리
--------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end

	-- 엑덱에서 랭크 ±3 "Aero Maneuver Ace" 선택
	if Duel.GetLocationCountFromEx(tp,tp,tc,nil)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter_ex,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc)
	local sc=g:GetFirst()
	if not sc then return end

	-- 소재 이관 + 엑시즈 소환 처리
	local mg=tc:GetOverlayGroup()
	if #mg>0 then
		Duel.Overlay(sc,mg)
	end
	sc:SetMaterial(Group.FromCards(tc))
	Duel.Overlay(sc,Group.FromCards(tc))
	Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()

	-- 특소된 몬스터는 이 턴 동안 상대 카드 효과의 대상이 되지 않음
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1)) -- "이 턴에 이 카드는 상대 카드 효과의 대상이 되지 않는다." 같은 텍스트
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.tgoval) -- 상대 효과만 막는 기본 값
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	sc:RegisterEffect(e1)
end
