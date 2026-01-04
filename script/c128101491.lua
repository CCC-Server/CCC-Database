--검투수 신규 10레벨 융합 (수정본)
local s,id=GetID()
local SET_GLADIATOR_BEAST=0x19

s.listed_series={SET_GLADIATOR_BEAST}

function s.initial_effect(c)
	-- 융합 소재: "검투수" 몬스터 x 3
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter,3,3)
	
	-- 콘택트 융합
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.contactcon)
	e0:SetTarget(s.contacttg)
	e0:SetOperation(s.contactop)
	c:RegisterEffect(e0)

	-- ①: 프리 체인 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- ②: 태그 아웃 (배틀 페이즈 종료 시)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1}) 
	e2:SetCondition(s.tagcon_bp)
	e2:SetCost(s.tagcost)
	e2:SetTarget(s.tagtg)
	e2:SetOperation(s.tagop)
	c:RegisterEffect(e2)

	-- ②: 태그 아웃 (상대 효과 발동 시)
	local e3=Effect.CreateEffect(c)
	e3:SetCountLimit(1,{id,1}) 
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1}) -- 배틀 페이즈 효과와 횟수 공유
	-- 데미지 스텝에도 발동 가능하게 설정 (전투 관련 효과 대응)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetCondition(s.tagcon_chain)
	e3:SetCost(s.tagcost)
	e3:SetTarget(s.tagtg)
	e3:SetOperation(s.tagop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- 콘택트 융합 처리
--------------------------------------------------------------------------------
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_GLADIATOR_BEAST,fc,sumtype,tp)
end

function s.contactfilter(c,tp)
	return c:IsSetCard(SET_GLADIATOR_BEAST) 
		and (c:IsAbleToDeckOrExtraAsCost() or c:IsAbleToExtra() or c:IsAbleToDeck())
		and (c:IsControler(tp) or c:IsFaceup())
end

function s.contactcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE,0,nil,tp)
	return g:GetCount()>=3 and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end

function s.contacttg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE,0,nil,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=g:Select(tp,3,3,nil)
	if #sg==3 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.contactop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	Duel.ConfirmCards(1-tp,sg)
	Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_COST+REASON_MATERIAL)
	sg:DeleteGroup()
end

--------------------------------------------------------------------------------
-- ①: 프리 체인 제외 효과
--------------------------------------------------------------------------------
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- ②: 태그 아웃 효과 (수정됨)
--------------------------------------------------------------------------------
-- 조건 1: 배틀 페이즈 종료 시 (전투 실행 여부 확인)
function s.tagcon_bp(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetBattledGroupCount()>0
end
-- 조건 2: 상대 효과 발동 시 (데미지 스텝 포함)
function s.tagcon_chain(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

-- 코스트: 자신을 엑스트라 덱으로 되돌림 (IsAbleToExtra 사용)
function s.tagcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtra() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

-- 대상 필터: 레벨 10 이하 "검투수" 융합 몬스터
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsType(TYPE_FUSION) 
		and c:IsLevelBelow(10)
		-- 소환 조건 무시 (true)
		and c:IsCanBeSpecialSummoned(e,113,tp,true,false)
end

function s.tagtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- 코스트로 필드를 벗어날 때(엑덱으로 돌아감) 생기는 공간을 미리 계산
		local ft_ex = Duel.GetLocationCountFromEx(tp,tp,c)
		local ft_main = Duel.GetMZoneCount(tp,c)
		
		-- 묘지에서 소환 (메인 몬스터 존 필요)
		local has_grave = ft_main>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		-- 엑스트라 덱에서 소환
		local has_extra = ft_ex>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
		
		return has_grave or has_extra
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end

function s.tagop(e,tp,eg,ep,ev,re,r,rp)
	-- 코스트 지불 후 현재 소환 가능한 공간 확인
	local ft_main = Duel.GetLocationCount(tp,LOCATION_MZONE)
	local ft_ex = Duel.GetLocationCountFromEx(tp)
	
	local g = Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,nil,e,tp)
	
	-- 소환 가능한 위치에 있는 몬스터만 필터링
	local valid_g = g:Filter(function(tc)
		if tc:IsLocation(LOCATION_EXTRA) then return ft_ex>0
		elseif tc:IsLocation(LOCATION_GRAVE) then return ft_main>0
		else return false end
	end, nil)
	
	if #valid_g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=valid_g:Select(tp,1,1,nil)
		if #sg>0 then
			-- 소환 조건 무시(true), 소환 타입 113 (검투수 룰)
			Duel.SpecialSummon(sg,113,tp,tp,true,false,POS_FACEUP)
		end
	end
end