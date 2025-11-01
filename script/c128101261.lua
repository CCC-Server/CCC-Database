--암군 레피렘 융합체
--Scripted by ChatGPT (Final Version)
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,128101256,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK))

	-- 글로벌 상태 플래그: 상대 효과 발동 체크
	if not s.global_check then
		s.global_check=true
		s[0]=false
		s[1]=false
		-- 상대가 카드 효과 발동했는지 감지
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
			if re:IsActivated() then
				s[rp] = true
			end
		end)
		Duel.RegisterEffect(ge1,0)

		-- 매 턴 시작 시 초기화
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
			s[0]=false
			s[1]=false
		end)
		Duel.RegisterEffect(ge2,0)
	end

	--① 융합 소환 성공 시: 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--② 필드 카드 되돌리고 몬스터면 암군 회수
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_END_PHASE)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc45,SET_FUSION}
s.listed_names={128101256} -- 암군 레피렘

-------------------------------------------------
--① 융합 소환 성공 시: 세트
-------------------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-- 암군 마/함
function s.setfilter1(c)
	return c:IsSetCard(0xc45) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable()
end
-- 융합/퓨전 관련 마/함 (일반/속공/일반 함정)
function s.setfilter2(c)
	return (c:IsSetCard(SET_FUSION) or c:IsCode(CARD_POLYMERIZATION))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local opp_used_effect = s[1-tp] -- 상대가 이 턴에 카드 효과 발동했는지 확인
	e:SetLabel(opp_used_effect and 1 or 0)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter1,tp,LOCATION_DECK,0,1,nil)
			or (opp_used_effect and Duel.IsExistingMatchingCard(s.setfilter2,tp,LOCATION_DECK,0,1,nil))
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local opp_used_effect = e:GetLabel() == 1
	local g=nil
	if opp_used_effect and Duel.IsExistingMatchingCard(s.setfilter2,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		-- 융합 관련 세트
		g=Duel.SelectMatchingCard(tp,s.setfilter2,tp,LOCATION_DECK,0,1,1,nil)
	else
		-- 암군 마/함 세트
		g=Duel.SelectMatchingCard(tp,s.setfilter1,tp,LOCATION_DECK,0,1,1,nil)
	end
	if #g>0 then
		Duel.SSet(tp,g)
		local tc=g:GetFirst()
		-- 세트한 턴에는 발동 불가
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_TRIGGER)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_SZONE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

-------------------------------------------------
--② 카드 되돌림 + (몬스터면 암군 회수)
-------------------------------------------------
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsMonster() then
		local g=Duel.GetMatchingGroup(function(c)
			return c:IsSetCard(0xc45) and c:IsAbleToHand()
		end,tp,LOCATION_GRAVE,0,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g:Select(tp,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end
