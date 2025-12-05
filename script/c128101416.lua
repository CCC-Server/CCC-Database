--호루스 의식 서포트 (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- "호루스의 흑염룡" 카드군 코드

function s.initial_effect(c)
	--------------------------------------
	-- (1) 이번 턴에 호루스 카드 효과가 발동되었으면
	--     패에서 프리체인으로 자신 특수 소환 (퀵)
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id) -- (1)(2) 공유 HOPT
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)

	--------------------------------------
	-- (2) 소환 / 특소 성공시 :
	--     호루스 의식 마법 1장 + 호루스 몬스터 1장 덱에서 서치
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- (1)(2) 공유 HOPT
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	--------------------------------------
	-- (3) 드래곤 의식 몬스터 의식 소환 시,
	--     이 카드를 전체 릴리스로 사용할 수 있음
	--------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_RITUAL_LEVEL)
	e3:SetValue(s.rlevel)
	c:RegisterEffect(e3)

	--------------------------------------
	-- 전역 처리 : "호루스의 흑염룡" 카드 효과 발동 체크
	--------------------------------------
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

--------------------------------------------------
-- 전역 : 이번 턴에 호루스 카드 효과 발동 여부 체크
--------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if rc:IsSetCard(SET_HORUS) then
		-- 어느 플레이어든 호루스 카드 효과가 발동되면 양쪽 모두 플래그 ON
		Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1)
		Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1)
	end
end

--------------------------------------------------
-- (1) 패에서 특소 : 조건/타겟/처리
--------------------------------------------------
function s.hspcon(e,tp,eg,ep,ev,re,r,rp)
	-- 이번 턴에 호루스 카드 효과가 발동되었는가?
	return Duel.GetFlagEffect(tp,id)>0
end
function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.hspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------------------------
-- (2) 서치 : 호루스 의식 마법 1장 + 호루스 몬스터 1장
--------------------------------------------------
function s.ritspfilter(c)
	-- "Horus the Black Flame Dragon" Ritual Spell
	return c:IsSetCard(SET_HORUS) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_SPELL)
		and c:IsAbleToHand()
end
function s.monfilter(c)
	-- "Horus the Black Flame Dragon" 몬스터
	return c:IsSetCard(SET_HORUS) and c:IsMonster()
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ritspfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.monfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Group.CreateGroup()
	-- 의식 마법 1장
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.ritspfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1==0 then return end
	g:Merge(g1)
	-- 호루스 몬스터 1장
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g2=Duel.SelectMatchingCard(tp,s.monfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g2==0 then return end
	g:Merge(g2)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------
-- (3) 의식 레벨 보정 : 드래곤 의식 몬스터 소환 시 전체 릴리스 취급
--------------------------------------------------
function s.rlevel(e,c)
	local lv=e:GetHandler():GetLevel()
	-- 드래곤족 의식 몬스터를 의식 소환할 때,
	-- 이 카드의 레벨을 그 의식 몬스터의 레벨로 취급
	if c:IsRace(RACE_DRAGON) and c:IsType(TYPE_RITUAL) then
		return c:GetLevel()
	end
	return lv
end
