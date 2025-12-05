--Fight Call - Rope-a-Dope
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49        -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50           -- "Fight Call"
local SET_AEROMANEUVER_ACE=0xc51    -- "Aero Maneuver Ace" (있으면 사용, 없어도 동작하게 처리)

function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL,SET_AEROMANEUVER_ACE}

	--------------------------------
	-- (1) 발동 : 상대 S/T 1장 파괴 후,
	--     자신 필드의 "Aero Maneuver Ace" 엑시즈를 소재로
	--     그보다 랭크가 3 높은 "Aero Maneuver" 엑시즈를 엑스트라 덱에서 특소
	--     (이 특소는 엑시즈 소환으로 취급 / 소재도 이으면서 겹침)
	--     이 카드명은 1턴에 1번만 발동 가능
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- "Aero Maneuver Ace" 엑시즈 판정 헬퍼
--  - 0xc51 세트코드가 있으면 그걸로,
--  - 없으면 0xc49(일반 Aero Maneuver) Xyz도 허용
--------------------------------
local function isAceXyz(c)
	return c:IsType(TYPE_XYZ)
		and (c:IsSetCard(SET_AEROMANEUVER_ACE) or c:IsSetCard(SET_AEROMANEUVER))
end

--------------------------------
-- 상대 마/함 파괴 대상
--------------------------------
function s.stfilter(c)
	return c:IsSpellTrap() and c:IsDestructable()
end

--------------------------------
-- 자신 필드의 소재 후보 : "Aero Maneuver Ace" 엑시즈 몬스터
-- 이 카드의 랭크 + 3인 "Aero Maneuver Ace/Aero Maneuver" 엑시즈가 엑덱에 있어야 함
--------------------------------
function s.xyzfilter(c,e,tp,mc,reqrk)
	return isAceXyz(c)
		and c:IsRank(reqrk)
		and mc:IsCanBeXyzMaterial(c,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

function s.matfilter(c,e,tp)
	if not (c:IsFaceup() and isAceXyz(c)) then
		return false
	end
	local rk=c:GetRank()
	return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,rk+3)
end

--------------------------------
-- 타깃 설정
-- 1) 상대 필드의 마/함 1장
-- + 조건 체크: 자신 필드에 랭크 업 가능한 "Aero Maneuver Ace" 엑시즈가 존재하는가
--------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.stfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.stfilter,tp,0,LOCATION_ONFIELD,1,nil)
			and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.stfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--------------------------------
-- 발동 처리
-- 1) 대상 마/함 파괴에 성공하면
-- 2) 자신 필드의 "Aero Maneuver Ace" 엑시즈 1장 선택
-- 3) 그 랭크 +3의 "Aero Maneuver Ace/Aero Maneuver" 엑시즈를 엑덱에서 특소 (엑시즈 소환 처리)
--------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	-- 1) 파괴 성공해야 나머지 진행
	if Duel.Destroy(tc,REASON_EFFECT)==0 then return end

	-- 2) 랭크 업용 소재 선택
	if not Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil,e,tp) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local mg=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	local mc=mg:GetFirst()
	if not mc then return end

	-- 3) 엑스트라 덱에서 랭크 +3 "Aero Maneuver" 엑시즈 선택
	if mc:IsFacedown() or not mc:IsRelateToEffect(e) then return end
	local rk=mc:GetRank()
	if rk<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mc,rk+3)
	local sc=sg:GetFirst()
	if not sc then return end

	-- 4) 소재 이관 + 엑시즈 소환 처리
	local overlay_group=mc:GetOverlayGroup()
	if #overlay_group>0 then
		Duel.Overlay(sc,overlay_group)
	end
	sc:SetMaterial(Group.FromCards(mc))
	Duel.Overlay(sc,Group.FromCards(mc))

	Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()
end
